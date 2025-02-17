-- 動画メタデータの追加（既存のカラムは除外）
alter table public.videos
add column if not exists thumbnail_url text;

-- duration制限の追加
do $$ 
begin
    if not exists (
        select 1 from pg_constraint 
        where conname = 'video_duration_check'
    ) then
        alter table public.videos
        add constraint video_duration_check 
            check (duration <= 180);
    end if;
end $$;