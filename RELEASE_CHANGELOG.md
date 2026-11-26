# Auctionator Remastered — Full Patch Notes

A remastered edition of Auctionator 3.1.5 for World of Warcraft: Wrath of the Lich King 3.3.5a, developed and tested on Warmane. This document brings together the additions, interface improvements and fixes made since the original addon.

**Auctionator Remastered by Nisho.** Based on the original Auctionator by **Zirco (Thunderhorn US)**. Original contributor credits are retained.

## 1.0.1 — 2026-11-26

- Isolate Remastered version requests and replies from original Auctionator's addon-message channel, preventing original version 3.1.5 from being reported as an update to Remastered 1.x.
- Compare release-version components numerically, so values such as 1.0.10 and 1.0.9 are ordered correctly. Keep the existing shopping-list sharing channel unchanged.
- Make Shopping Planner a top-level window and raise it when shown or opened again, so it comes in front of Offline Browser when opened through Shopping lists.
- Preserve saved data and preferences. Installation ZIPs contain only the two addon folders at the root.

## 1.0.0 — 2026-11-26

The first stable release of Auctionator Remastered for WoW 3.3.5a. The sections below describe the changes since 0.9.0-beta.2; the rest of this document retains the broader Remastered feature history.

### Installation package

- Keep only `AuctionatorRemastered/` and `AuctionatorRemastered_Startup/` in the installation ZIP root. Documentation is available on GitHub, outside the download package.

### Buying and recent searches

- Replace the inherited batch-buy loop with an acknowledgement-driven queue. Each purchase requires a user click; subsequent purchases are prepared after server responses and refreshed auction results.
- Match item identity, stack size, buyout price and applicable seller information before submitting a purchase. Do not reuse a stale row index after auctions move or disappear.
- Count confirmed purchases rather than treating submitted requests as successful purchases. Bound query and confirmation waits, stop on interruptions, and offer a user-driven Refresh when results do not advance.
- Keep the selected quantity and cumulative purchase progress in the existing purchase dialog.
- Keep recent searches in most-recent-first order, avoid case-only duplicates, highlight the active search immediately, and preserve scroll position when a search finishes.
- Align Search, Advanced, Full Scan and Options, with matching search-field and Recent Searches dropdown styling.
- Style the existing purchase/error message window for Standard WoW and ElvUI; wrap long messages and retain acknowledgement and mask behavior.

### Disenchanting and Jewelcrafting

- Calculate disenchant estimates from the latest saved lowest prices of output materials, looked up by item ID even when client names are not cached.
- Support all seven Lesser/Greater essence pairs in both directions at three lesser essences per greater essence, using the cheaper direct or converted equivalent when available.
- Normalize outcome probabilities and retain intermediate fractions until the expected-value calculation is complete. Missing or invalid material prices show unknown instead of a misleading incomplete total.
- Mark estimates based on old, partial-scan or undated material prices.
- Add prospecting estimates per five ore for Copper, Tin, Iron, Mithril, Thorium, Fel Iron, Adamantite, Cobalt, Saronite and Titanium. Include the applicable powders and independent additional gem rolls.
- Show possible materials, drop chances, quantity ranges and each material's saved lowest unit price in both material breakdowns.
- Give prospecting its own value checkbox and independent Shift, Control, Alt, Always and Never material-detail choices. Group the Tooltips page into general prices, disenchanting and prospecting.
- Use AzerothCore WotLK loot tables for prospecting estimates. Actual server rates may differ. Material values are gross estimates before AH fees, rather than guaranteed returns.

### Trading Logs

- Add Today alongside 7 days, 30 days and All time.
- Add From/To date filters in YYYY-MM-DD format; include the entire end date. Validate invalid dates and reversed ranges without applying a broken filter.
- Replace the single-character checkbox with a multiple-selection character dropdown, including All characters and Only this character shortcuts.
- Combine character, date, item-name and activity filters. Recalculate displayed spending, listed value and item quantities for the selected results.
- Add Reset filters and align both filter rows. Keep the ledgers scoped to the selected realm and faction.

### Appearance and settings

- Add an explicit Standard WoW / ElvUI preference, applied after Reload UI. Selecting Standard WoW suppresses the conflicting Auctionator/auction-house skin paths without disabling unrelated ElvUI skins.
- Add independent background-transparency controls for the auction house, Offline Browser and Shopping Planner. Keep text, icons, buttons and borders at their normal opacity.
- Match the native Sell sidebar bounds to Buy/Undercuts. Extend hover and selected-row highlights only into unused sidebar space; keep visible scrollbar controls clear in both themes.
- Center empty-view guidance and use a consistent orange color across the updated views.
- Fit the settings pages into the original Interface options window. Align fields, dropdown captions and labels without relying on another addon's options-window resizer.
- Retain all Database status information in compact cards and add hover help for Last complete. Simplify About to credits, feedback links and version information.
- Fix Offline Browser/bag frame interleaving by raising the Browser as a complete top-level window.
- Add an old-price warning shared by Offline Browser and Deals. Its default is one day; it marks prices without hiding or deleting them.
- Add independent Full Scan chat-summary and completion-sound preferences. Chat summaries default on; sounds default off. Cancelled, failed and partial scans do not play the completion sound.
- Require confirmation when lowering the history-retention setting. Keep the previous limit if the confirmation is cancelled; changing the setting does not immediately prune data.

### Reviewed first-install defaults

| Setting | Default |
| --- | --- |
| Alt shortcut / open all bags | On / On |
| Starting Price on Sell | Off |
| Auction duration / initial tab | 12 hours / None |
| Browse Market % / Full Scan chat summary / sound | On / On / Off |
| Vendor, AH, disenchant and prospecting values | On |
| Shift price mode / DE and JC breakdowns | Stack price / while Shift is held |
| Minimum scan quality | Poor (all) |
| Market comparison / history retention | 14 days / 30 days |
| Mark saved prices as old | After 1 day |
| Show incomplete Browser items | Off |
| Stacking category overrides | None; default behavior |
| Starting-bid discount | 5% |

- Retain existing valid saved preferences; these defaults do not reset an upgraded user's settings.
- Automatically use ElvUI when available unless Standard WoW was explicitly chosen. Browser transparency defaults on in ElvUI and off in Standard WoW; Shopping Planner defaults opaque. Auction-house backgrounds retain their native/skin defaults unless overridden.
- Retain the existing undercut thresholds: above 500g → 1g, 100g → 25s, 20g → 10s, 5g → 5s, 1g → 2s, 20s → 1s, and 5s → 5c.

### Organization, validation and known limitations

- Keep inherited engine code under Legacy, with Remastered behavior separated into Models, Data, UI, Integration and Features. Split auction layout/dialogs, shared settings, Database status and prospecting into focused modules.
- Validate load references, XML includes, Lua 5.1 syntax and model boundaries. Regression coverage includes database identity, purchases, confirmed postings, scanning, filters, saved preferences, material estimates and both UI themes.
- Purchase requests can still be rejected or time out during live play. Auction availability may change, and server/client restrictions can interrupt a batch; the exact cause of intermittent Warmane purchase failures is not confirmed. Check purchase results before retrying after a confirmation timeout.
- Existing Remastered prices and preferences are preserved. Replace both addon folders and restart WoW completely when updating to load the new files.

## 0.9.0-beta.2 — 2026-11-21

### Interface

- Introduce a warm anthracite standard-WoW theme with distinct content panels and stronger bronze-grey borders across Buy, Sell, Undercuts, Deals, Trading Logs, Full Scan, Offline Browser, Shopping Planner and price history.
- Preserve the existing ElvUI appearance and layout.
- Tidy Sell's pricing and quantity controls, keep maximum-quantity labels clear of dividers, and align Buy's shopping-list buttons and panel edges.
- Place the close X consistently in the upper-right corner of the updated auction-house views.

### Fixes

- Fix a bag-update Lua error when other group members disenchant items.
- Refresh Sell results after confirmed auction postings, including single auctions and batches, without requiring a manual refresh.
- Avoid counting overlapping posting confirmations twice or adding unconfirmed auctions after a failed batch.

## Remastered database

- Store prices under stable item-ID/signed-suffix keys, with locale-specific name aliases and separate realm/faction histories.
- Keep learned static metadata separate from price observations. A bundled icon or cached name never creates a market price.
- Detect ambiguous same-name identities and retain both canonical records without guessing on name-only lookups.
- Collect full-scan variant minima in a temporary batch, prepare history privately, and publish only after processing finishes. Leaving the AH discards uncommitted work.
- Version and validate the saved format, distinguish actual item observations from completed full-scan timestamps, and retain bounded historical samples.
- Reuse reference calculations and Browser snapshots with invalidation on writes, metadata changes, reference-window changes and day rollover.
- Prune in place and preserve Clear/Undo, including observations acquired after a clear. Correct the daily-low case when a subsequent price rises.
- Start fresh without automatic legacy import and retain old WTF files unchanged.

## Offline auction browser

- Added a standalone browser for saved auction prices, available anywhere without visiting the auction house.
- Open it with the minimap button, `/atr browse` or `/atrbrowse`.
- Browse the current realm and faction's saved prices, including retained history-only price records.
- Search saved item names without sending an auction query or loading the auction-house interface.
- Added an expandable category tree with item counts, subcategories and equipment slots, such as Armor → Cloth → Head.
- Group chest pieces and robes under the same Chest slot.
- Added scrolling for long category trees and consistent indentation for categories, subcategories and slots.
- Added account-wide favorites with clickable stars and a dedicated Favorites view.
- Search and sort favorites using the same controls as the rest of the browser.
- Added sortable columns for item name, lowest saved price per item, reference price, Market % and update age.
- Column headings reverse sorting direction when clicked again and show the active direction arrow.
- Added item icons, normal item tooltips and a selected-item details area with scrollable daily-low history.
- Avoid duplicate Auctionator pricing lines when the normal item tooltip already includes them.
- Added a bundled metadata-only item catalog to improve icons, categories and item identity when client-cache information is unavailable.
- Use exact ID/suffix metadata and consistent fields observed for the same base ID. Remove name-family inference and generated reserve-catalog tooltip links.
- Keep bundled metadata separate from the user's scanned prices, settings and trading records.
- Learn and retain additional metadata through full scans, normal auction browsing and item-link lookups.
- Missing information never overwrites previously learned item details.
- Hide items with missing categories, subcategories or equipment slots by default. The Unclassified category is also hidden while this option is off.
- Added Interface → Auctionator → Offline Browser → Show incomplete items to restore the complete saved-item view, including unknown categories and slots.
- Hiding incomplete items preserves prices, history and shopping-list entries.
- Added a separately saved Transparent background preference for the browser.
- Shift-click a bag item to search its name without first focusing the search box. Supported profession output links and Skillet recipe selections can also fill the browser search.
- Linked searches clear restrictive category selections so the requested item can be found.
- Uncached item links can use their displayed name for searching.
- Link handling works before the first auction-house visit after login or reload.
- Keep active chat and other edit-box input working normally.
- Added right-click actions for adding items to existing shopping lists or creating a new list.
- Preserve normal item-link sharing to an open chat box.

## Price history charts

- Added an independent, movable price-history chart for saved items.
- Switch between 7-, 14- and 30-day views.
- Plot saved daily lowest buyouts per item, with exact dates and prices on hover.
- Connect only adjacent recorded days; missing days remain visible as gaps rather than becoming zero-price points.
- Show the latest saved price, recorded-day count, lowest and highest daily lows, and the median of the displayed daily lows.
- Added daily percentage changes and comparisons against the previous calendar day.
- Falling prices appear green, rising prices red and unchanged prices yellow. Missing previous-day data is shown explicitly.
- Added clear empty-history and single-record states.
- Use solid chart and plot backgrounds for readability over other windows.

## Market price comparisons

- Added colored Market % comparisons to native Browse results and Auctionator's current Buy/Sell results.
- Display percentages in the offline browser and item pricing tooltips as well.
- Compare individual-item prices consistently, including auctions sold in stacks.
- Added configurable 3-, 5-, 7-, 14- and 30-day reference windows under Database settings; the default is 14 days.
- Calculate references from the median of available daily scan medians, excluding the current day and giving each recorded day equal weight.
- Retain up to one lowest-price observation per item per hour, with up to 24 observations per day. Latest saved prices still update with each scan.
- Use older daily-low history as a fallback where daily scan medians are unavailable.
- Use the latest saved low as the reference when no earlier history exists.
- Mark references with fewer than three previous history days using an asterisk.
- Use green below 95% of reference, yellow from 95–105%, and red above 105%.
- Added a Buy reference summary showing the comparison price, selected period and available history coverage.
- Keep that summary out of empty, multi-item summary and Sell views.
- Added a sortable Market % column to native Browse. Click again to reverse its direction.
- Put unknown references and auctions without a buyout at the end of Market % sorting.
- Preserve native auction identities when sorting, including row selection, scrolling, tooltips, bids and buyouts.
- Selecting another native sort column clears the custom Market % sorting mode.
- Added a saved Basic Options setting to show or hide the Browse Market % column. Hiding it restores the original item-name space and native ordering.
- Matched Market % header fonts, arrows, hover and pressed states to the other headers in both standard UI and ElvUI.
- Corrected Rarity's hit area and highlight boundaries so they do not extend across Market %.
- Removed the extra Settings shortcut beside Browse's Reset button; its setting remains available through Interface options.

## Deals

- Added a Deals tab between Undercuts and Logs for finding potential bargains in saved scan data.
- Added filters for item name, maximum Market %, minimum profit per item, maximum price age and minimum history coverage.
- Added editable resale-price assumptions and auction-house commission.
- Default filters use a maximum of 70% of reference, at least 1g potential profit, prices up to 24 hours old and three previous days of history.
- Default resale estimates use 95% of reference with a 5% AH commission.
- Calculate estimated resale, AH fee, proceeds after the fee and potential profit per item.
- Reuse the offline browser's expandable category and equipment-slot tree, with Favorites and counts reflecting matching deals.
- Keep name, Max Market % and Min profit in the main toolbar; place the less frequently changed assumptions in a compact Settings dialog.
- Replace separate Refresh and Sort controls with automatic updates and clickable column headings.
- Refresh after saved database changes and as saved prices age.
- Added sortable Item, Saved buy, Est. profit, Market % and Updated columns, with highest profit first by default.
- Improved spacing between Saved buy and Est. profit and reduced unused space in Updated.
- Shortened age labels in the table while keeping exact scan timestamps in the details view.
- Show the original item tooltip on hover when an exact item link is available, including supported random-suffix variants.
- Added a separate Deal details window beside the auction house, updating as different deals are inspected.
- Group details into per-item prices, resale estimates and price history, with aligned labels and values.
- Show saved buy price, usual price, buy-versus-usual percentage, assumed sale price, AH fee, proceeds, potential profit, history coverage and the last scan timestamp.
- Highlight potential profit and distinguish limited history coverage without repeating a separate warning paragraph.
- Keep the last inspected deal visible when the mouse leaves its row; clear details when the item no longer belongs to the results.
- Match the details window to the AH's height and scale, following it by default.
- Allow detaching and moving the details window independently, with saved placement and a Reset position button to reattach it.
- Match the details background transparency to the main auction window.
- Separate click instructions into readable rows.
- Left-click a deal to open its price chart; right-click to switch to Buy and search the exact item.
- Prevent the Buy handoff during an active full scan.
- Shift-click bag items to fill Deals search without first focusing the search field.
- Added centered empty-result guidance, now using the shared orange presentation.
- Clarified the footer: prices are saved per-item values, current prices should be checked in Buy, and deposits/relisting fees are excluded.

## Shopping lists and planning

- Added a standalone shopping-list manager accessible from the offline browser and Buy's Manage Shopping Lists button.
- Use the same saved lists in the offline manager and live Buy tab.
- Create, rename and delete lists, remove entries and add items through the browser's right-click menu.
- Require confirmation before deleting a list.
- Reject duplicate names and entries and respect the existing 50-item list limit.
- Keep Buy's current list and dropdown synchronized after list changes and sorting.
- Update nested-list references when lists are renamed or deleted.
- Select the current Buy list when opening the manager where available.
- Added a quantity planner with Want, Owned, Need and estimated cost.
- New unset quantity targets start at zero; existing saved targets are preserved.
- Save edited targets with Enter or when leaving the quantity field.
- Count current-character bag inventory, with optional last-recorded bank contents.
- Refresh recorded bank contents when visiting the bank and update bag counts as inventory changes.
- Highlight completed entries and show the remaining quantity needed.
- Estimate cost from saved per-item prices and clearly identify partial estimates when prices are missing or an entry is a search term.
- Keep quantity targets shared with the list while inventory counts remain character-specific.
- Added item icons, clearer price labels, grouped list-management controls and dedicated scrollbars.
- Added a separately saved Transparent background preference; the planner defaults to an opaque background.
- Replaced the legacy Shopping Lists settings page with the standalone manager.
- Corrected Buy's Add Item and Remove Item actions to use the opened item's exact name rather than an earlier broad search term. Multi-item summaries can still save search terms.
- Removing an entry also removes its associated planner target.

## Purchases, postings and trading logs

- Added My Purchases beside Current, History and My Auctions.
- Record accepted buyouts made through Auctionator or native Browse, including quantity, price per item, total paid, buying character, timestamp and seller when available.
- Exclude ordinary bids, failed requests, expired pending requests and unrelated server messages from purchase totals.
- Renamed Other to My Auctions and expanded posting information with item counts, stack breakdowns, date/time, posting character and status.
- Added separate detailed posting records for new Auctionator batches while retaining legacy posting summaries.
- Mark incomplete older posting data as Legacy rather than presenting it as a complete modern record.
- Added a unified Trading logs tab for purchases and auction listings on the current realm/faction.
- Added item-name search, All/Bought/Listed activity filters, 7-day/30-day/all-time ranges and a current-character filter.
- Click any log column to sort matching records and click again to reverse the direction. Default order is newest first.
- Added filtered totals for money spent, purchased quantity, listed value and listed quantity.
- Keep listed value separate from actual sales revenue.
- Added row tooltips with stack details and seller names when available.
- Added Deals-style alternating row backgrounds and space for one additional visible entry.
- Improved labels to Activity and Time range and replaced technical empty-result wording with clearer guidance.
- Shift-click bag items into Logs search without first focusing the search field.
- Store new purchase and posting ledgers across characters by realm/faction, with record limits and age-based pruning.
- Corrected interrupted multi-sell logging to count confirmed progress instead of an extra unconfirmed stack.
- Refresh matching open Sell, Buy and Undercuts results after confirmed postings, including when the shared scan cache has been replaced.
- Avoid duplicate updates of shared scan objects and ignore zero-progress posting updates.

## Buy and Sell workflow

- Added per-item purchase totals for the current AH visit in Buy and the confirmation dialog.
- Count individual items across mixed stack sizes, sellers, price rows and purchase batches.
- Show full inventory-stack equivalents plus the remainder and total item count where stack size is known.
- Show the amount spent on the selected item in the confirmation dialog.
- Retain visit totals while switching items or reopening the dialog; reset them on a new AH visit or UI reload.
- Prevent pending purchase acknowledgements from an earlier visit entering the new visit's totals.
- Redesigned the buy-confirmation dialog with a compact opaque background, separate item heading and aligned unit-price, quantity and total-cost rows.
- Keep prices close to their labels and align the maximum quantity and total item count with their associated controls.
- Improve the contrast of supporting quantity text.
- Show unit prices for single items as well as stacks.
- Preserve quantity validation, Enter-to-buy behavior, disabled states, batch progress and Buy/Cancel actions.
- Align recommended stack and per-item Sell prices beneath their heading, clear of the result tabs.
- Correct the ElvUI Sell drop target so its outline and mouse area stay inside the visible auction window after updates and tab changes.
- Fit the Create Auction button inside the Sell controls.
- Shift-left-click a bag item while Sell is open to load it directly into the selling pane using the existing item-loading flow.
- Keep auction creation on the normal Create Auction action.
- Rename the old More tab to Undercuts.

## Full Scan and database tools

- Replace the inherited full-scan lifecycle with a dedicated Remastered engine while retaining the normal fast bulk request and page-by-page slow scan APIs.
- Redesigned Full Scan as a compact, centered, opaque dialog with standard-UI controls and optional ElvUI skins.
- Added a live estimated fast-scan cooldown countdown, with server readiness taking precedence.
- Show a waiting-for-server state when the estimated timer has expired but the server still blocks scanning.
- Allow an explicit early fast-scan attempt through a confirmation warning. The server or client may still reject it.
- Prevent early-attempt confirmation from restarting an active scan or acting on a closed dialog or changed scan mode.
- Display completed fast and slow scan counts below the database item count.
- Add scan statistics covering modes, durations, completed scan counts and last-scan results.
- Show retained history dates, available days and item/day record counts in Database settings.
- Keep result-summary values aligned and prevent legacy result colors from replacing the new dialog background.
- Increase default history retention to 30 days while preserving larger existing limits.
- Require confirmation before clearing current realm/faction price data.
- Add Undo clear until logout or reload, preserving prices collected after the clear.
- Keep shopping lists, posting history and scan cooldowns when clearing price data.
- Retain available item icons, quality, exact auction links and IDs during full scans.
- Resolve additional category and equipment metadata from the client cache in bounded background work after scan cleanup, even with the browser closed.
- Limit metadata retries and isolate metadata lookup failures from price-scan processing.
- Remove the separate offline item-info scan and its Update item info button; full scans now collect prices and available metadata together.
- Suspend ElvUI's visual AFK screen only during page-by-page slow Full Scan and restore the previous setting on completion, cancellation or AH close.

### Rebuilt analysis, progress and cancellation

- Replace per-auction busy waiting and the inherited 0.2-second scan-processing cadence with a frame driver bounded by time and row count.
- Analyze up to 1,000 auction rows or approximately 3 ms per frame, yielding control to the client between batches.
- Remove duplicate name-keyed price aggregation; use canonical item-ID/suffix minima and count actual variants in added/updated/ignored results.
- Prepare history and median samples on detached records, at most 256 records or approximately 3 ms per step, before one final publication boundary.
- Invalidate the active database cache once when publishing the prepared scan instead of repeatedly during preparation.
- Add a 30-second timeout for unanswered requests or unavailable query readiness; never automatically repeat a fast bulk request.
- Limit slow-page retries for missing item names to two, without staging or counting a retried page twice.
- Finish slow scans on their reported final page, including exact multiples of 50, rather than requesting an extra empty page.
- Detect competing auction searches and stop before their shared result buffer can contaminate the current scan.
- Remove completion's dependence on a successful empty-buffer cleanup search and remove the forced full garbage collection.
- Show fast progress in whole thousands, independently of scan-processing speed.
- Give active scans a separate progress area with auction count, elapsed time, and slow-scan time remaining on individual lines; hide idle tools and generic help until the scan ends.
- Estimate slow-scan time remaining after five completed pages, excluding time in the stop/save chooser. Smooth estimates at five-second intervals and apply a ten-second margin around minute boundaries.
- Keep long status and error messages wrapped inside the scan dialog.
- Add Stop and save, Keep scanning and Discard scan choices. Escape keeps scanning. Stop and save publishes only fully read slow pages and excludes an unfinished page.
- Keep automatic AH close, logout, query interruption and timeout non-saving; already published prices remain untouched.
- Mark stopped/partial observations and show an item-tooltip notice. Later complete scans or normal observations clear that marker.
- Keep partial scans out of successful fast/slow counters and preserve the last-complete timestamp.
- Read the database item count from canonical priced variants and unresolved records, rather than the transient name view.
- Keep the fast-request cooldown estimate separate from the last analyzed scan shown in the dialog.
- Print a multi-line fast/slow scan summary with duration, auction count, item changes and quality counts using WoW's rarity colors. Show Poor/Common on one line and Uncommon/Rare/Epic on the next, with higher qualities when present.
- Deduplicate full-scan metadata by item identity and reuse the exact links already read by the price scanner.

## Tooltips and profession integration

- Group saved auction information under an Auctionator heading with the age of the last scan.
- Show the colored market percentage beside the saved lowest price without requiring Shift.
- Hold Shift for reference details, stack value and estimated proceeds after the AH cut.
- Keep vendor information separate from auction-price information.
- Use the same configurable market reference across tooltips and auction comparisons.
- Correct stack quantities supplied to auction sell-slot and loot-window tooltips.
- Added a compact Scan AH control and explanatory tooltip for supported profession panels, including Skillet integration.
- Reject invalid recipe selections and competing scans before changing AH panes.

## Window placement, skins and interface polish

- Style all auction tabs through ElvUI’s native tab helper when ElvUI is available, including dynamically added Deals and Logs tabs, without requiring AddOnSkins.
- Allow moving the auction window by dragging its title area without covering existing action controls.
- Save AH placement when moving or closing it and restore it across visits and sessions.
- Keep detached Deal details placement independent from AH placement.
- Added Appearance settings to allow or disable AH movement and independently reset either window.
- Reattach Deal details beside AH when resetting its position.
- Reorder Interface settings to Basic Options, Appearance, Tooltips, Offline Browser, Selling, Undercutting, Database, Clears and About.
- Match Deals, Logs, the offline browser, shopping planner and dialogs to the standard UI or active ElvUI styling.
- Apply ElvUI button, input, checkbox and scrollbar skins where available while retaining native controls without ElvUI.
- Block the known legacy ElvUI AddOnSkins Auctionator callback from modifying Remastered, even when its checkbox is enabled. Preserve the standard ElvUI auction-house skin and other addon skins.
- Align analysis panels to the visible AH shell and normal tab strip, accounting for effective scale and selected-tab artwork.
- Restore original AH decorations and gold visibility when leaving analysis tabs.
- Correct footer spacing, close-button padding, shopping controls, money positioning and result-list margins.
- Place list, category and history scrollbars in separate gutters so rows and highlights stay inside their content borders.
- Replace the Buy and Undercuts sidebar backgrounds with a continuous theme-matched surface behind both content and scrollbar space.
- Remove lingering white divider textures, exposed vanilla background seams and the extra dark divider left behind when the scrollbar is hidden.
- Keep all active-item rows reachable in the shorter ElvUI Undercuts sidebar.
- Added a draggable minimap launcher with saved angle and visibility, plus `/atr minimap` to show or hide it.
- Correct icon size, centering, circular-border alignment and placement for supported minimap shapes and sizes.
- Avoid overriding launcher placement after an icon collector reparents it.
- Expose the launcher under the Auctionator Remastered name in compatible icon collectors while retaining the legacy global alias.
- Use Shift-right-click for database settings so ordinary right-clicks do not open options accidentally; update the tooltip accordingly.

### Additional interface and reliability fixes

- Resize Buy, Sell, Undercuts, Deals and Logs immediately after their text/font is assigned so the first AH opening does not compress the tabs.
- Keep selected standard-WoW tabs at their inactive height and use the blue highlight to identify selection; retain ElvUI's tab styling.
- Remove category tooltips that only repeat category names/counts in the offline browser and Deals.
- Restore saved-price tooltip information when item-cache or recipe addons rebuild the first-hover tooltip, without repeatedly appending prices.
- Keep Market % on a single header line in Deals and improve spacing beside its neighboring columns.
- Initialize the load-on-demand module after its own SavedVariables are available; handle either Blizzard auction-UI load order and keep initialization idempotent.
- Keep the installation-conflict chooser's text and controls above its background in both native and ElvUI presentation.

## Internal organization

- Separate inherited auction-engine code from Remastered features so Buy, Sell and other original components can be replaced gradually.
- Split shared styling, window placement, browser data and categories, Deals calculations, trading-log calculations and the minimap launcher into dedicated modules.
- Centralize integration with original engine observers and exact-item Buy navigation while keeping public entry points compatible. The new Remastered installation uses its own saved database.
- Add load-order, file-reference, Lua syntax and regression checks, including a synthetic 52,612-auction response, same-name variants, staged history preparation, cancellation, partial saves, retries, timeout and both UI themes.

## Installation and compatibility notes

- Target client: World of Warcraft 3.3.5a. Standard UI and ElvUI are supported.
- Install AuctionatorRemastered and AuctionatorRemastered_Startup. Seller names and merchant pricing are built in; remove the obsolete MiniFeatures companion.
- First installation starts with a clean Remastered database. Old Auctionator SavedVariables remain untouched and are not imported.
- Later updates preserve Remastered data. Unknown database versions are reported without automatically wiping them.
- Release packages contain addon files, not personal WTF settings, scanned account data or trading logs.
- Release ZIPs contain only the two addon folders at the root, for addon-manager compatibility. README and detailed patch notes remain on GitHub.
- Restart WoW fully after installing new addon files. Later edits to already loaded Lua files normally need only `/reload`.

## Current limitations

- Native Browse Market % sorting covers the current returned result page, up to 50 auctions. Sorting across every auction page is not included in this release.
- Offline prices, Deals and planner estimates use saved scans. They do not establish current availability, actual sale prices or guaranteed resale profit.
- Deal estimates exclude deposits and relisting costs. The selected resale assumption and AH fee can be changed in Deals settings.
- Charts show daily lows; their displayed median is different from the daily-median market reference.
- Metadata coverage depends on the bundled catalog and information available from the client or returned auctions. Incomplete entries can be shown through the offline-browser setting.
- New purchase and posting records cannot reconstruct earlier transactions. Historical scan counts also begin when the new tracking is installed.
- Posting records describe listings. Mail-based sold, expired and cancelled outcome tracking is not included.
- An early fast-scan attempt does not bypass server cooldown enforcement.
