# YouTube API audit: answers for the form

Form: https://support.google.com/youtube/contact/yt_api_form ("YouTube Data API Services – Audit and Quota Extension
Form"). Why: until the project passes this audit, every video uploaded through the API stays private, even with a
publish time. Submit it signed in as **contact@kallistesoft.ca**, the owner of the Cloud project.

Before submitting:
- [ ] kallistesoft-site PR #39 merged and live (the privacy and terms pages below must load).
- [ ] Screenshots taken (list at the end).

## Section 1: Request type
- Reason: **Complete a compliance audit to request for additional quota**. It's the only option for a first audit.
  The quota question further down is answered "No change / Default quota".

## Section 2: Organization and contact
- Applying: **As an organization**
- Your full legal name: **Jean-François Poughon**
- Organization's legal name: **9536-3529 Québec inc.** (operating as Kallistesoft)
- Parent company: (blank)
- Primary website: **https://kallistesoft.ca/en/**
- Country: **Canada**. Address: **529 4th Avenue**, **Saint-Jean-sur-Richelieu**, **Quebec**, **J2X 1X3**
- Category: software / mobile games (closest option offered)
- Organization size: **Startup (fewer than 10 employees)**
- Primary contact: **Jean-François Poughon**, **contact@kallistesoft.ca**. Technical contact: **Same as primary contact**. Business
  contact: (blank)

## Section 3: Business model
- **Describe your organization's work as it relates to YouTube:**
  > Kallistesoft (9536-3529 Québec inc.) is a small software studio in Québec, Canada, that makes mobile puzzle games
  > for Google Play (Critter Logic, Block Daily, and others). We promote our own games with short gameplay videos on
  > our own YouTube channel, "KallisteSoft". Our API client, "KallisteSoft Shorts", is an internal command-line tool
  > that only uploads and schedules these Shorts on our own channel. Each day it records the previous day's daily
  > puzzle from our own game, edits a ~17-second vertical video, and uploads it with videos.insert as private with a
  > publishAt time. It has no other users, no public interface, and reads no YouTube data.
- Target audience: **Internal Users**
- Monetization: **Free service (we do not charge users)**. The tool earns nothing. It promotes our own games.
- Ads on/within YouTube content: **Not applicable**
- Google or YouTube representative: **No, I do not have a Google representative**
- How did you learn about the API: Google developer documentation (YouTube Data API v3 docs)
- Content Owner IDs: (blank, no Content Manager)

## Section 4: API client
- API client name: **KallisteSoft Shorts**. Contains "YouTube": **No**
- Primary access URL: **https://github.com/kallistesoft/critter-logic/blob/main/tools/daily_shorts.py** (the tool's
  public source code; it has no web interface). If the form needs a site, use https://kallistesoft.ca/en/.
- Privacy policy URL: **https://kallistesoft.ca/en/privacy/kallistesoft-shorts/**
- Terms of service URL: **https://kallistesoft.ca/en/terms/kallistesoft-shorts/**
- Publicly accessible: **No**
- Demo account: (none: no sign-in of ours exists). Special instructions:
  > Internal command-line tool run by Kallistesoft staff only; there is nothing to log in to. Its full source code is
  > public at the URL above (see upload() for the only API call, videos.insert). Screenshots of the OAuth consent,
  > the upload run and the resulting scheduled video in YouTube Studio are attached.

## Section 5: Use case and quota
- Number of project numbers: **1**
- Google Cloud project number: **356692462858** (project ID `kallistesoft-youtube`)
- Use case categories: **Video Uploading & Account Management** and **Internal Company Tool**
- Users sign in with Google: **Yes** (OAuth installed-app flow, only the channel owner, scope `youtube.upload`)
- Additional policies: tick that you agree.
- Expected usage: **No change / Default quota (10k quota points)**. Roughly 1 to 3 videos.insert per day (one Short
  per day per game), at most 6 a day when scheduling a week ahead.
- Endpoints: **youtube.videos.insert** only

### Evidence for project 1
Required:
1. **Privacy policy screenshots**: the full page https://kallistesoft.ca/en/privacy/kallistesoft-shorts/. It shows
   section 1 (YouTube API Services, YouTube ToS and Google Privacy Policy links) and section 4 (revocation, deletion).
2. **Homepage screenshot showing the privacy link**: https://kallistesoft.ca/en/ footer with "Privacy", plus
   https://kallistesoft.ca/en/privacy/ section 4 listing "KallisteSoft Shorts".
3. **Terms of service documentation**: screenshot or PDF of https://kallistesoft.ca/en/terms/kallistesoft-shorts/
   ("By using the tool, you agree to be bound by the YouTube Terms of Service").

Conditional:
- a) **OAuth flow**: the consent screen at `login` (app name, scope "Manage your YouTube videos" / upload), and
  https://myaccount.google.com/connections showing "KallisteSoft Shorts" with its remove-access option.
- b) **Upload interface**: the terminal running `python3 tools/daily_shorts.py upload` (titles, publish times, Shorts
  links), and YouTube Studio → Content showing the uploaded Short as Scheduled.

## Section 6: Documents
- Architecture diagram: `store/shorts/audit/architecture.png`
- User flow diagram: `store/shorts/audit/user-flow.png`
- Other: (optional) one rendered Short, e.g. `build/shorts/2026-11-14-en.mp4`

## Section 7: Attestations
Read and tick each box yourself (YouTube API ToS, Google Privacy Policy, Developer Policies, termination, accuracy,
data use). The demo-account waiver doesn't apply.
