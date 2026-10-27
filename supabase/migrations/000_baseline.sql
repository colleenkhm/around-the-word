-- Baseline: prod schema dumped 2026-10-26 (001-004 were never committed).
-- Includes everything through 033. Fresh projects: push this, then mark 005-033 applied.



SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name" "text" NOT NULL,
    "parent_id" "uuid",
    "sort_order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "population" integer,
    "latitude" numeric,
    "longitude" numeric,
    "is_major" boolean DEFAULT false NOT NULL,
    "is_featured" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "why_featured" "text",
    "country_id" "text" NOT NULL
);


ALTER TABLE "public"."cities" OWNER TO "postgres";


COMMENT ON COLUMN "public"."cities"."why_featured" IS 'Editorial note on why this city is featured. Curated, never touched by the commodity importer.';



CREATE TABLE IF NOT EXISTS "public"."coming_soon_resources" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "url" "text" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "country_id" "text"
);


ALTER TABLE "public"."coming_soon_resources" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."content_candidates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "country_id" "text" NOT NULL,
    "candidate_type" "text" NOT NULL,
    "source" "text" NOT NULL,
    "source_url" "text",
    "payload" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "reviewed_at" timestamp with time zone,
    "notes" "text",
    "fetched_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "content_candidates_candidate_type_check" CHECK (("candidate_type" = ANY (ARRAY['poi'::"text", 'phrase'::"text", 'word'::"text", 'historical_event'::"text", 'festival'::"text"]))),
    CONSTRAINT "content_candidates_source_check" CHECK (("source" = ANY (ARRAY['wikivoyage'::"text", 'wiktionary'::"text", 'wikidata'::"text"]))),
    CONSTRAINT "content_candidates_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."content_candidates" OWNER TO "postgres";


COMMENT ON TABLE "public"."content_candidates" IS 'Tier B staging queue (see CLAUDE.md External Data Sources, tier B). Never read by the app. Promotion to the real table is manual — see this migration''s header for the licensing reason approved must mean rewritten, not just fetched.';



CREATE TABLE IF NOT EXISTS "public"."contributors" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "display_name" "text" NOT NULL,
    "relationship" "text",
    "wants_credit" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."contributors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."correction_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "subject_type" "text",
    "subject_id" "uuid",
    "report_text" "text" NOT NULL,
    "reporter_contact" "text",
    "source_url" "text",
    "status" "text" DEFAULT 'new'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "resolved_at" timestamp with time zone,
    "country_id" "text" NOT NULL,
    CONSTRAINT "correction_reports_status_check" CHECK (("status" = ANY (ARRAY['new'::"text", 'checking'::"text", 'actioned'::"text", 'dismissed'::"text"]))),
    CONSTRAINT "correction_reports_subject_type_check" CHECK (("subject_type" = ANY (ARRAY['leadership'::"text", 'advisory'::"text", 'visa'::"text", 'best_time'::"text", 'phrase'::"text", 'general'::"text"])))
);


ALTER TABLE "public"."correction_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."countries" (
    "id" "text" NOT NULL,
    "iso_code" "text" NOT NULL,
    "name_common" "text" NOT NULL,
    "name_official" "text",
    "is_published" boolean DEFAULT false NOT NULL,
    "content_status" "text" DEFAULT 'none'::"text" NOT NULL,
    "language_scope_na" boolean DEFAULT false NOT NULL,
    "regional_group" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "state_dept_entry_exit_code" "text",
    CONSTRAINT "countries_content_status_check" CHECK (("content_status" = ANY (ARRAY['none'::"text", 'partial'::"text", 'complete'::"text"])))
);


ALTER TABLE "public"."countries" OWNER TO "postgres";


COMMENT ON COLUMN "public"."countries"."state_dept_entry_exit_code" IS 'Verified working country code for cadataapi.state.gov''s entry_exit_requirements endpoint, when it differs from iso_code. Null = iso_code already works. That endpoint is keyed closer to FIPS 10-4 than ISO 3166-1 for a known subset of countries — see HANDOFF.md 2026-08-21.';



CREATE TABLE IF NOT EXISTS "public"."country_contributors" (
    "contributor_id" "uuid" NOT NULL,
    "country_id" "text" NOT NULL
);


ALTER TABLE "public"."country_contributors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."country_facts" (
    "flag_svg_url" "text",
    "capital" "text",
    "population" integer,
    "currency_code" "text",
    "currency_name" "text",
    "calling_code" "text",
    "official_languages" "jsonb",
    "latitude" numeric,
    "longitude" numeric,
    "hemisphere" "text",
    "neighbors" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "region" "text",
    "subregion" "text",
    "source" "text",
    "last_imported_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "timezone" "text",
    "country_id" "text" NOT NULL,
    CONSTRAINT "country_facts_hemisphere_check" CHECK (("hemisphere" = ANY (ARRAY['Northern'::"text", 'Southern'::"text"])))
);


ALTER TABLE "public"."country_facts" OWNER TO "postgres";


COMMENT ON COLUMN "public"."country_facts"."timezone" IS 'IANA timezone name, e.g. "Europe/Athens". Commodity — importer-owned like capital/currency, respects the same source-guard as other country_facts columns.';



CREATE TABLE IF NOT EXISTS "public"."country_guides" (
    "best_times" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "practical_norms" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "dress_expectations" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "cuisine_notes" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "historical_events" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "festivals" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "prep_notes" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "author_notes" "text",
    "last_reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "country_id" "text" NOT NULL
);


ALTER TABLE "public"."country_guides" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."country_languages" (
    "language_id" "uuid" NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "usage_note" "text",
    "country_id" "text" NOT NULL,
    "is_official" boolean DEFAULT true NOT NULL,
    "percent_speakers" numeric,
    "percent_speakers_source" "text",
    "percent_status" "text" DEFAULT 'needs_research'::"text" NOT NULL,
    "percent_year" integer,
    "percent_source_url" "text",
    CONSTRAINT "country_languages_percent_status_check" CHECK (("percent_status" = ANY (ARRAY['verified'::"text", 'unverified'::"text", 'no_source'::"text", 'needs_research'::"text"])))
);


ALTER TABLE "public"."country_languages" OWNER TO "postgres";


COMMENT ON COLUMN "public"."country_languages"."is_official" IS 'true = official language of the country; false = commonly spoken but not official (a widely-taught second language, a regional indigenous or creole language). Hand-curated — see CLAUDE.md External Data Sources, Tier C.';



COMMENT ON COLUMN "public"."country_languages"."percent_speakers" IS 'Approximate % of the population who speak this language, where a sourced figure exists. Null, not 0, when none exists, never guessed. English rows: sourced via fetch_english_speakers.py; other languages hand-curated.';



COMMENT ON COLUMN "public"."country_languages"."percent_speakers_source" IS 'Where percent_speakers came from and what it measures. Null exactly when percent_speakers is null or predates this column.';



COMMENT ON COLUMN "public"."country_languages"."percent_status" IS 'Verification state of percent_speakers. Only verified figures are shown in the app. See migration 030.';



COMMENT ON COLUMN "public"."country_languages"."percent_year" IS 'Year the percent_speakers figure was measured (survey/census year), not the year it was entered.';



COMMENT ON COLUMN "public"."country_languages"."percent_source_url" IS 'Link to the primary source percent_speakers was verified against.';



CREATE TABLE IF NOT EXISTS "public"."country_leadership" (
    "title" "text",
    "name" "text",
    "since" "date",
    "source_url" "text",
    "last_verified_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "country_id" "text" NOT NULL
);


ALTER TABLE "public"."country_leadership" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exchange_rate_cache" (
    "currency_code" "text" NOT NULL,
    "rate_from_usd" numeric NOT NULL,
    "fetched_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."exchange_rate_cache" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."languages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "iso_code" "text" NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."languages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."phrase_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "phrase_id" "uuid" NOT NULL,
    "position" integer NOT NULL,
    "surface_form" "text" NOT NULL,
    "word_id" "uuid",
    "is_maskable" boolean DEFAULT false NOT NULL,
    "token_type" "text" NOT NULL,
    CONSTRAINT "phrase_tokens_token_type_check" CHECK (("token_type" = ANY (ARRAY['word'::"text", 'punctuation'::"text", 'particle'::"text"])))
);


ALTER TABLE "public"."phrase_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."phrases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "language_id" "uuid" NOT NULL,
    "category_id" "uuid",
    "text" "text" NOT NULL,
    "translation" "text" NOT NULL,
    "literal_translation" "text",
    "pronunciation" "text",
    "audio_url" "text",
    "formality" "text",
    "usage_note" "text",
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "country_id" "text" NOT NULL,
    CONSTRAINT "phrases_formality_check" CHECK (("formality" = ANY (ARRAY['formal'::"text", 'informal'::"text", 'either'::"text"])))
);


ALTER TABLE "public"."phrases" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."points_of_interest" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "city_id" "uuid",
    "poi_type" "text" NOT NULL,
    "tags" "text",
    "name" "text" NOT NULL,
    "description" "text",
    "dress_code" "text",
    "visit_notes" "text",
    "latitude" numeric,
    "longitude" numeric,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "country_id" "text" NOT NULL,
    CONSTRAINT "points_of_interest_poi_type_check" CHECK (("poi_type" = ANY (ARRAY['landmark'::"text", 'restaurant'::"text", 'neighborhood'::"text", 'activity'::"text"])))
);


ALTER TABLE "public"."points_of_interest" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."public_holidays" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "country_id" "text" NOT NULL,
    "date" "date" NOT NULL,
    "local_name" "text" NOT NULL,
    "name" "text" NOT NULL,
    "is_national" boolean NOT NULL,
    "holiday_type" "text",
    "source" "text" DEFAULT 'nager.date'::"text" NOT NULL,
    "last_imported_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."public_holidays" OWNER TO "postgres";


COMMENT ON TABLE "public"."public_holidays" IS 'Commodity, Tier A (see CLAUDE.md External Data Sources). Sourced from Nager.Date, rebuildable from the importer. Distinct from country_guides.festivals, which stays hand-curated.';



CREATE TABLE IF NOT EXISTS "public"."regional_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_slug" "text" NOT NULL,
    "note_type" "text" DEFAULT 'visa'::"text" NOT NULL,
    "summary" "text",
    "official_url" "text",
    "last_verified_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."regional_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."research_submissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "contributor_id" "uuid",
    "submitted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "form_version" "text",
    "subject_type" "text",
    "subject_id" "uuid",
    "agrees" boolean,
    "structured" "jsonb",
    "free_text" "jsonb",
    "visited_when" "text",
    "notes" "text",
    "country_id" "text" NOT NULL,
    CONSTRAINT "research_submissions_subject_type_check" CHECK (("subject_type" = ANY (ARRAY['best_time'::"text", 'advisory'::"text", 'visa'::"text", 'general'::"text"])))
);


ALTER TABLE "public"."research_submissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tips" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "city_id" "uuid",
    "category_id" "uuid",
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "published_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "country_id" "text" NOT NULL
);


ALTER TABLE "public"."tips" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."travel_advisories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "issuing_authority" "text" NOT NULL,
    "level" "text",
    "level_label" "text",
    "summary" "text",
    "official_url" "text" NOT NULL,
    "issued_at" "date",
    "last_verified_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "country_id" "text" NOT NULL
);


ALTER TABLE "public"."travel_advisories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."visa_requirements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "summary" "text",
    "official_url" "text",
    "application_url" "text",
    "last_verified_at" timestamp with time zone,
    "prohibited_on_entry" "text",
    "prohibited_on_exit" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "issuing_authority" "text",
    "destination_country_id" "text" NOT NULL,
    "nationality_country_id" "text" NOT NULL
);


ALTER TABLE "public"."visa_requirements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."word_categories" (
    "word_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL
);


ALTER TABLE "public"."word_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."words" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "language_id" "uuid" NOT NULL,
    "lemma" "text" NOT NULL,
    "translation" "text" NOT NULL,
    "part_of_speech" "text",
    "gender" "text",
    "pronunciation" "text",
    "ipa" "text",
    "audio_url" "text",
    "usage_note" "text",
    "difficulty" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "country_id" "text" NOT NULL
);


ALTER TABLE "public"."words" OWNER TO "postgres";


ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."cities"
    ADD CONSTRAINT "cities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."coming_soon_resources"
    ADD CONSTRAINT "coming_soon_resources_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."content_candidates"
    ADD CONSTRAINT "content_candidates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contributors"
    ADD CONSTRAINT "contributors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."correction_reports"
    ADD CONSTRAINT "correction_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."countries"
    ADD CONSTRAINT "countries_iso_code_key" UNIQUE ("iso_code");



ALTER TABLE ONLY "public"."countries"
    ADD CONSTRAINT "countries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."country_contributors"
    ADD CONSTRAINT "country_contributors_pkey" PRIMARY KEY ("country_id", "contributor_id");



ALTER TABLE ONLY "public"."country_facts"
    ADD CONSTRAINT "country_facts_pkey" PRIMARY KEY ("country_id");



ALTER TABLE ONLY "public"."country_guides"
    ADD CONSTRAINT "country_guides_pkey" PRIMARY KEY ("country_id");



ALTER TABLE ONLY "public"."country_languages"
    ADD CONSTRAINT "country_languages_pkey" PRIMARY KEY ("country_id", "language_id");



ALTER TABLE ONLY "public"."country_leadership"
    ADD CONSTRAINT "country_leadership_pkey" PRIMARY KEY ("country_id");



ALTER TABLE ONLY "public"."exchange_rate_cache"
    ADD CONSTRAINT "exchange_rate_cache_pkey" PRIMARY KEY ("currency_code");



ALTER TABLE ONLY "public"."languages"
    ADD CONSTRAINT "languages_iso_code_key" UNIQUE ("iso_code");



ALTER TABLE ONLY "public"."languages"
    ADD CONSTRAINT "languages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."phrase_tokens"
    ADD CONSTRAINT "phrase_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."phrases"
    ADD CONSTRAINT "phrases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."points_of_interest"
    ADD CONSTRAINT "points_of_interest_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."public_holidays"
    ADD CONSTRAINT "public_holidays_country_id_date_name_key" UNIQUE ("country_id", "date", "name");



ALTER TABLE ONLY "public"."public_holidays"
    ADD CONSTRAINT "public_holidays_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."regional_notes"
    ADD CONSTRAINT "regional_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."research_submissions"
    ADD CONSTRAINT "research_submissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tips"
    ADD CONSTRAINT "tips_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."travel_advisories"
    ADD CONSTRAINT "travel_advisories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."visa_requirements"
    ADD CONSTRAINT "visa_requirements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."word_categories"
    ADD CONSTRAINT "word_categories_pkey" PRIMARY KEY ("word_id", "category_id");



ALTER TABLE ONLY "public"."words"
    ADD CONSTRAINT "words_pkey" PRIMARY KEY ("id");



CREATE INDEX "content_candidates_country_id_idx" ON "public"."content_candidates" USING "btree" ("country_id");



CREATE INDEX "content_candidates_status_idx" ON "public"."content_candidates" USING "btree" ("status");



CREATE INDEX "content_candidates_type_idx" ON "public"."content_candidates" USING "btree" ("candidate_type");



CREATE INDEX "idx_advisories_country" ON "public"."travel_advisories" USING "btree" ("country_id");



CREATE INDEX "idx_cities_country" ON "public"."cities" USING "btree" ("country_id");



CREATE INDEX "idx_phrase_tokens_phrase" ON "public"."phrase_tokens" USING "btree" ("phrase_id");



CREATE INDEX "idx_phrases_country" ON "public"."phrases" USING "btree" ("country_id");



CREATE INDEX "idx_poi_country" ON "public"."points_of_interest" USING "btree" ("country_id");



CREATE INDEX "idx_visa_dest" ON "public"."visa_requirements" USING "btree" ("destination_country_id", "nationality_country_id");



CREATE INDEX "idx_words_country" ON "public"."words" USING "btree" ("country_id");



CREATE INDEX "public_holidays_country_id_idx" ON "public"."public_holidays" USING "btree" ("country_id");



CREATE UNIQUE INDEX "travel_advisories_country_authority_key" ON "public"."travel_advisories" USING "btree" ("country_id", "issuing_authority");



CREATE UNIQUE INDEX "visa_requirements_destination_nationality_key" ON "public"."visa_requirements" USING "btree" ("destination_country_id", "nationality_country_id");



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."cities" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."countries" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."country_facts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."country_guides" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."country_leadership" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."points_of_interest" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_updated_at" BEFORE UPDATE ON "public"."regional_notes" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."cities"
    ADD CONSTRAINT "cities_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."coming_soon_resources"
    ADD CONSTRAINT "coming_soon_resources_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content_candidates"
    ADD CONSTRAINT "content_candidates_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."correction_reports"
    ADD CONSTRAINT "correction_reports_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."country_contributors"
    ADD CONSTRAINT "country_contributors_contributor_id_fkey" FOREIGN KEY ("contributor_id") REFERENCES "public"."contributors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."country_contributors"
    ADD CONSTRAINT "country_contributors_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."country_facts"
    ADD CONSTRAINT "country_facts_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."country_guides"
    ADD CONSTRAINT "country_guides_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."country_languages"
    ADD CONSTRAINT "country_languages_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."country_languages"
    ADD CONSTRAINT "country_languages_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."country_leadership"
    ADD CONSTRAINT "country_leadership_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."phrase_tokens"
    ADD CONSTRAINT "phrase_tokens_phrase_id_fkey" FOREIGN KEY ("phrase_id") REFERENCES "public"."phrases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."phrase_tokens"
    ADD CONSTRAINT "phrase_tokens_word_id_fkey" FOREIGN KEY ("word_id") REFERENCES "public"."words"("id");



ALTER TABLE ONLY "public"."phrases"
    ADD CONSTRAINT "phrases_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."phrases"
    ADD CONSTRAINT "phrases_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."phrases"
    ADD CONSTRAINT "phrases_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id");



ALTER TABLE ONLY "public"."points_of_interest"
    ADD CONSTRAINT "points_of_interest_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "public"."cities"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."points_of_interest"
    ADD CONSTRAINT "points_of_interest_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."public_holidays"
    ADD CONSTRAINT "public_holidays_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."research_submissions"
    ADD CONSTRAINT "research_submissions_contributor_id_fkey" FOREIGN KEY ("contributor_id") REFERENCES "public"."contributors"("id");



ALTER TABLE ONLY "public"."research_submissions"
    ADD CONSTRAINT "research_submissions_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tips"
    ADD CONSTRAINT "tips_category_fk" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."tips"
    ADD CONSTRAINT "tips_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "public"."cities"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."tips"
    ADD CONSTRAINT "tips_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."travel_advisories"
    ADD CONSTRAINT "travel_advisories_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."visa_requirements"
    ADD CONSTRAINT "visa_requirements_destination_country_id_fkey" FOREIGN KEY ("destination_country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."visa_requirements"
    ADD CONSTRAINT "visa_requirements_nationality_country_id_fkey" FOREIGN KEY ("nationality_country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."word_categories"
    ADD CONSTRAINT "word_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."word_categories"
    ADD CONSTRAINT "word_categories_word_id_fkey" FOREIGN KEY ("word_id") REFERENCES "public"."words"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."words"
    ADD CONSTRAINT "words_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "public"."countries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."words"
    ADD CONSTRAINT "words_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id");



ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."coming_soon_resources" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."content_candidates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contributors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."correction_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."countries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."country_contributors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."country_facts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."country_guides" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."country_languages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."country_leadership" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."exchange_rate_cache" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."languages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."phrase_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."phrases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."points_of_interest" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "public read" ON "public"."categories" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."cities" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."coming_soon_resources" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."countries" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."country_facts" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."country_guides" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."country_languages" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."languages" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."phrase_tokens" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."phrases" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."points_of_interest" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."regional_notes" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."tips" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."travel_advisories" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."visa_requirements" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."word_categories" FOR SELECT USING (true);



CREATE POLICY "public read" ON "public"."words" FOR SELECT USING (true);



ALTER TABLE "public"."public_holidays" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "public_holidays_read" ON "public"."public_holidays" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."regional_notes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."research_submissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tips" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."travel_advisories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."visa_requirements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."word_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."words" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";


















GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."cities" TO "anon";
GRANT ALL ON TABLE "public"."cities" TO "authenticated";
GRANT ALL ON TABLE "public"."cities" TO "service_role";



GRANT ALL ON TABLE "public"."coming_soon_resources" TO "anon";
GRANT ALL ON TABLE "public"."coming_soon_resources" TO "authenticated";
GRANT ALL ON TABLE "public"."coming_soon_resources" TO "service_role";



GRANT ALL ON TABLE "public"."content_candidates" TO "anon";
GRANT ALL ON TABLE "public"."content_candidates" TO "authenticated";
GRANT ALL ON TABLE "public"."content_candidates" TO "service_role";



GRANT ALL ON TABLE "public"."contributors" TO "anon";
GRANT ALL ON TABLE "public"."contributors" TO "authenticated";
GRANT ALL ON TABLE "public"."contributors" TO "service_role";



GRANT ALL ON TABLE "public"."correction_reports" TO "anon";
GRANT ALL ON TABLE "public"."correction_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."correction_reports" TO "service_role";



GRANT ALL ON TABLE "public"."countries" TO "anon";
GRANT ALL ON TABLE "public"."countries" TO "authenticated";
GRANT ALL ON TABLE "public"."countries" TO "service_role";



GRANT ALL ON TABLE "public"."country_contributors" TO "anon";
GRANT ALL ON TABLE "public"."country_contributors" TO "authenticated";
GRANT ALL ON TABLE "public"."country_contributors" TO "service_role";



GRANT ALL ON TABLE "public"."country_facts" TO "anon";
GRANT ALL ON TABLE "public"."country_facts" TO "authenticated";
GRANT ALL ON TABLE "public"."country_facts" TO "service_role";



GRANT ALL ON TABLE "public"."country_guides" TO "anon";
GRANT ALL ON TABLE "public"."country_guides" TO "authenticated";
GRANT ALL ON TABLE "public"."country_guides" TO "service_role";



GRANT ALL ON TABLE "public"."country_languages" TO "anon";
GRANT ALL ON TABLE "public"."country_languages" TO "authenticated";
GRANT ALL ON TABLE "public"."country_languages" TO "service_role";



GRANT ALL ON TABLE "public"."country_leadership" TO "anon";
GRANT ALL ON TABLE "public"."country_leadership" TO "authenticated";
GRANT ALL ON TABLE "public"."country_leadership" TO "service_role";



GRANT ALL ON TABLE "public"."exchange_rate_cache" TO "anon";
GRANT ALL ON TABLE "public"."exchange_rate_cache" TO "authenticated";
GRANT ALL ON TABLE "public"."exchange_rate_cache" TO "service_role";



GRANT ALL ON TABLE "public"."languages" TO "anon";
GRANT ALL ON TABLE "public"."languages" TO "authenticated";
GRANT ALL ON TABLE "public"."languages" TO "service_role";



GRANT ALL ON TABLE "public"."phrase_tokens" TO "anon";
GRANT ALL ON TABLE "public"."phrase_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."phrase_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."phrases" TO "anon";
GRANT ALL ON TABLE "public"."phrases" TO "authenticated";
GRANT ALL ON TABLE "public"."phrases" TO "service_role";



GRANT ALL ON TABLE "public"."points_of_interest" TO "anon";
GRANT ALL ON TABLE "public"."points_of_interest" TO "authenticated";
GRANT ALL ON TABLE "public"."points_of_interest" TO "service_role";



GRANT ALL ON TABLE "public"."public_holidays" TO "anon";
GRANT ALL ON TABLE "public"."public_holidays" TO "authenticated";
GRANT ALL ON TABLE "public"."public_holidays" TO "service_role";



GRANT ALL ON TABLE "public"."regional_notes" TO "anon";
GRANT ALL ON TABLE "public"."regional_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."regional_notes" TO "service_role";



GRANT ALL ON TABLE "public"."research_submissions" TO "anon";
GRANT ALL ON TABLE "public"."research_submissions" TO "authenticated";
GRANT ALL ON TABLE "public"."research_submissions" TO "service_role";



GRANT ALL ON TABLE "public"."tips" TO "anon";
GRANT ALL ON TABLE "public"."tips" TO "authenticated";
GRANT ALL ON TABLE "public"."tips" TO "service_role";



GRANT ALL ON TABLE "public"."travel_advisories" TO "anon";
GRANT ALL ON TABLE "public"."travel_advisories" TO "authenticated";
GRANT ALL ON TABLE "public"."travel_advisories" TO "service_role";



GRANT ALL ON TABLE "public"."visa_requirements" TO "anon";
GRANT ALL ON TABLE "public"."visa_requirements" TO "authenticated";
GRANT ALL ON TABLE "public"."visa_requirements" TO "service_role";



GRANT ALL ON TABLE "public"."word_categories" TO "anon";
GRANT ALL ON TABLE "public"."word_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."word_categories" TO "service_role";



GRANT ALL ON TABLE "public"."words" TO "anon";
GRANT ALL ON TABLE "public"."words" TO "authenticated";
GRANT ALL ON TABLE "public"."words" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































