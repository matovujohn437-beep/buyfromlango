# Seller Tools Setup

Smart Responses and seller Tags use the Supabase tables and RPC functions in
`supabase/migrations/0021_seller_tools.sql`. Apply this migration to the
Supabase project before using these features:

```powershell
supabase db push
```

The Supabase CLI must be linked to the intended project, and the project's
earlier migrations must already be applied. Alternatively, apply the migration
through the Supabase SQL Editor.

Smart Responses are private to the signed-in user. Listing and conversation
Tags are also private to the user who assigns them; the migration restricts
listing tags to listing owners and conversation tags to participants. No
service-role key or additional client credential is required.
