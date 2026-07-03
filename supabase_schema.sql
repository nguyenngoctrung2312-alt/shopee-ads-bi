-- =========================================================================
-- SHOPEE ADS BI — FILE SQL DUY NHAT DE CHAY TREN SUPABASE
-- =========================================================================
-- Cach dung:
--   1. Vao Supabase Dashboard cua project ban -> SQL Editor -> New query
--   2. Dan TOAN BO noi dung file nay -> bam Run
--   3. Kiem tra: Table Editor phai thay 2 bang "ads_campaign_reports" va
--      "upload_history", cung view "v_ads_computed".
--
-- Noi dung file gom 2 phan:
--   PHAN 1: Tao bang, index, trigger, view (schema.sql)
--   PHAN 2: Bat Row Level Security + policies (policies.sql)
-- =========================================================================

-- ================================ PHAN 1 ================================
-- Nguon tham chieu: file "Data base.xlsx" (Sheet1) - Bao cao Chien dich /
-- Tu khoa - Vi tri do Shopee xuat ra. 36 cot du lieu goc duoc giu day du,
-- chi doi ten cot sang snake_case khong dau (bat buoc voi Postgres). Nhan
-- hien thi tren UI (index.html) van giu nguyen tieng Viet nhu file goc.

create extension if not exists "pgcrypto";

-- -------------------------------------------------------------------------
-- 1. BANG CHINH: ads_campaign_reports
-- Moi dong = 1 dong bao cao Chien dich/Tu khoa-Vi tri theo Thang/Nam.
-- -------------------------------------------------------------------------
create table if not exists public.ads_campaign_reports (
    id                          uuid primary key default gen_random_uuid(),

    -- Thong tin Shop (KHONG co trong file goc - bo sung de ho tro multi-shop,
    -- nguoi dung nhap/khai bao luc upload).
    shop_name                   text not null default 'Default Shop',

    -- ===== 36 cot du lieu goc tu Shopee (giu nguyen thu tu & y nghia) =====
    thang                       smallint not null,          -- Thang
    nam                         smallint not null,          -- Nam
    thu_tu                      integer,                    -- Thu tu
    ten_dich_vu_hien_thi        text,                        -- Ten Dich vu Hien thi (Campaign)
    trang_thai                  text,                        -- Trang thai
    loai_dich_vu_hien_thi       text,                        -- Loai Dich vu Hien thi
    ma_san_pham                 text,                        -- Ma san pham
    noi_dung_dich_vu_hien_thi   text,                        -- Noi dung Dich vu Hien thi
    phuong_thuc_dau_thau        text,                        -- Phuong thuc dau thau
    vi_tri                      text,                        -- Vi tri
    tu_khoa_vi_tri              text,                        -- Tu khoa / Vi tri
    loai_tu_khoa                text,                        -- Loai tu khoa
    ngay_bat_dau                date,                        -- Ngay bat dau
    ngay_ket_thuc               text,                        -- Ngay ket thuc ("Khong gioi han" hoac ngay)
    cot_an                      numeric,                     -- (Cot Shopee an)
    so_luot_xem                 bigint default 0,            -- So luot xem (Impressions)
    so_luot_click               bigint default 0,            -- So luot click (Clicks)
    ty_le_click                 numeric default 0,           -- Ty Le Click (CTR)
    luot_chuyen_doi             bigint default 0,            -- Luot chuyen doi
    luot_chuyen_doi_truc_tiep   bigint default 0,            -- Luot chuyen doi truc tiep
    ty_le_chuyen_doi            numeric default 0,           -- Ty le chuyen doi (CVR)
    ty_le_chuyen_doi_truc_tiep  numeric default 0,           -- Ty le chuyen doi truc tiep
    cpa                         numeric default 0,           -- Chi phi/luot chuyen doi
    cpa_truc_tiep               numeric default 0,           -- Chi phi/luot chuyen doi truc tiep
    san_pham_da_ban             bigint default 0,            -- San pham da ban (Orders)
    san_pham_da_ban_truc_tiep   bigint default 0,            -- San pham da ban truc tiep
    doanh_so                    numeric default 0,           -- Doanh so (Revenue)
    doanh_so_truc_tiep          numeric default 0,           -- Doanh so truc tiep
    chi_phi                     numeric default 0,           -- Chi phi (Ad Cost)
    roas                        numeric default 0,           -- ROAS
    roas_truc_tiep              numeric default 0,           -- ROAS truc tiep
    acos                        numeric default 0,           -- ACOS
    acos_truc_tiep              numeric default 0,           -- ACOS truc tiep
    luot_xem_san_pham           bigint default 0,            -- Luot xem San pham
    luot_click_san_pham         bigint default 0,            -- Luot clicks San pham
    ty_le_click_san_pham        numeric default 0,           -- Ty le Click San pham

    -- Du phong cho bao cao Shopee khac (vd: bao cao San pham) se bo sung sau,
    -- hien tai file goc chua co cot nay.
    add_to_cart                 bigint,                       -- Luot Them vao gio hang (chua co trong file hien tai)

    -- ===== Cot he thong / metadata =====
    period_date       date generated always as (make_date(nam::int, thang::int, 1)) stored,
    source_file_name  text,
    uploaded_by       uuid references auth.users(id),
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now(),

    -- Khoa tu nhien de CHONG TRUNG DU LIEU: neu 1 dong co cung
    -- shop + thang/nam + campaign + san pham + noi dung + vi tri + tu khoa
    -- + ngay bat dau -> coi la CUNG 1 DONG -> khi upload lai se UPDATE
    -- thay vi tao dong moi (INSERT). Gia tri nay duoc TRIGGER tinh tu dong
    -- truoc khi ghi (khong dung GENERATED COLUMN vi ep kieu date::text
    -- khong duoc Postgres coi la "immutable", se bi loi 42P17 khi tao bang).
    row_key text,

    constraint ads_campaign_reports_row_key_uniq unique (row_key)
);

comment on table public.ads_campaign_reports is
  'Bao cao Chien dich/Tu khoa-Vi tri Shopee Ads. Nguon: Data base.xlsx. Upsert theo row_key de tranh trung du lieu.';

create index if not exists idx_acr_period_date  on public.ads_campaign_reports (period_date);
create index if not exists idx_acr_shop         on public.ads_campaign_reports (shop_name);
create index if not exists idx_acr_campaign     on public.ads_campaign_reports (ten_dich_vu_hien_thi);
create index if not exists idx_acr_product      on public.ads_campaign_reports (ma_san_pham);
create index if not exists idx_acr_nam_thang    on public.ads_campaign_reports (nam, thang);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_acr_updated_at on public.ads_campaign_reports;
create trigger trg_acr_updated_at
  before update on public.ads_campaign_reports
  for each row execute function public.set_updated_at();

-- Tinh row_key (khoa chong trung) truoc moi lan INSERT/UPDATE.
-- Dat trong trigger (khong phai generated column) vi phep ep kieu
-- ngay_bat_dau::text phu thuoc DateStyle nen Postgres khong coi la immutable.
create or replace function public.set_row_key()
returns trigger as $$
begin
  new.row_key := md5(
    coalesce(new.shop_name,'') || '|' ||
    coalesce(new.thang::text,'') || '|' ||
    coalesce(new.nam::text,'') || '|' ||
    coalesce(new.ten_dich_vu_hien_thi,'') || '|' ||
    coalesce(new.ma_san_pham,'') || '|' ||
    coalesce(new.noi_dung_dich_vu_hien_thi,'') || '|' ||
    coalesce(new.vi_tri,'') || '|' ||
    coalesce(new.tu_khoa_vi_tri,'') || '|' ||
    coalesce(new.ngay_bat_dau::text,'')
  );
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_acr_row_key on public.ads_campaign_reports;
create trigger trg_acr_row_key
  before insert or update on public.ads_campaign_reports
  for each row execute function public.set_row_key();

-- -------------------------------------------------------------------------
-- 2. BANG LICH SU UPLOAD: upload_history
-- -------------------------------------------------------------------------
create table if not exists public.upload_history (
    id              uuid primary key default gen_random_uuid(),
    file_name       text not null,
    shop_name       text,
    uploaded_by     uuid references auth.users(id),
    total_rows      integer default 0,
    inserted_rows   integer default 0,
    updated_rows    integer default 0,
    error_rows      integer default 0,
    status          text not null default 'processing',
    error_detail    jsonb,
    created_at      timestamptz not null default now(),
    finished_at     timestamptz
);

comment on table public.upload_history is 'Lich su moi lan upload/dong bo file du lieu Shopee Ads.';
create index if not exists idx_uh_created_at on public.upload_history (created_at desc);

-- -------------------------------------------------------------------------
-- 3. VIEW TINH TOAN: v_ads_computed
-- Bo sung cac chi so KHONG co san trong file goc: CPC, CPM.
-- -------------------------------------------------------------------------
create or replace view public.v_ads_computed as
select
    r.*,
    case when so_luot_click > 0 then round((chi_phi / so_luot_click)::numeric, 2) else 0 end as cpc,
    case when so_luot_xem  > 0 then round((chi_phi / so_luot_xem * 1000)::numeric, 2) else 0 end as cpm
from public.ads_campaign_reports r;

comment on view public.v_ads_computed is 'View bo sung CPC = Chi phi/Click, CPM = Chi phi/1000 luot xem.';

-- ================================ PHAN 2 ================================
-- App noi bo (BI tool), chi user da dang nhap (authenticated) qua Supabase
-- Auth moi duoc doc/ghi du lieu. Neu sau nay can phan quyen theo Shop hoac
-- theo vai tro (admin/viewer), mo rong policy tai day.

alter table public.ads_campaign_reports enable row level security;
alter table public.upload_history       enable row level security;

-- ---- ads_campaign_reports ----
drop policy if exists "authenticated_select_reports" on public.ads_campaign_reports;
create policy "authenticated_select_reports"
  on public.ads_campaign_reports for select
  to authenticated
  using (true);

drop policy if exists "authenticated_insert_reports" on public.ads_campaign_reports;
create policy "authenticated_insert_reports"
  on public.ads_campaign_reports for insert
  to authenticated
  with check (true);

drop policy if exists "authenticated_update_reports" on public.ads_campaign_reports;
create policy "authenticated_update_reports"
  on public.ads_campaign_reports for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "authenticated_delete_reports" on public.ads_campaign_reports;
create policy "authenticated_delete_reports"
  on public.ads_campaign_reports for delete
  to authenticated
  using (true);

-- ---- upload_history ----
drop policy if exists "authenticated_select_history" on public.upload_history;
create policy "authenticated_select_history"
  on public.upload_history for select
  to authenticated
  using (true);

drop policy if exists "authenticated_insert_history" on public.upload_history;
create policy "authenticated_insert_history"
  on public.upload_history for insert
  to authenticated
  with check (true);

drop policy if exists "authenticated_update_history" on public.upload_history;
create policy "authenticated_update_history"
  on public.upload_history for update
  to authenticated
  using (true)
  with check (true);
