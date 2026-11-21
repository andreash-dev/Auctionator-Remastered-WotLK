# Auctionator Remastered

Auctionator Remastered expands the familiar Auctionator experience with an offline price browser, price history, deal discovery, shopping planning and trading logs — backed by a new item-based database and a rebuilt full-scan engine.

Developed by **Nisho** for **World of Warcraft 3.3.5a**, and tested on **Warmane**, Remastered keeps the familiar buying and selling workflow while adding new ways to explore and use your auction data.

**[Download the addon](https://github.com/andreash-dev/Auctionator-Remastered-WotLK/releases)** · **[Full patch notes](RELEASE_CHANGELOG.md)** · **[Installation](#installation)**

## Highlights

### Browse your auction data anywhere

- Open the **Offline Browser** without visiting the auction house.
- Search saved prices, compare market percentages and see when each item was last scanned.
- Explore expandable categories, subcategories and equipment slots.
- Save favorites for quick access.
- View item tooltips and open price charts directly from the browser.
- Incomplete item classifications are hidden by default, with an option to show them.

### Understand prices over time

- View **7-, 14- and 30-day price charts**.
- Compare prices against a configurable historical reference.
- See colored **Market %** values in supported auction views, the offline browser and item tooltips.
- Use historical daily medians to reduce the influence of individual price spikes.
- Identify limited history through the preliminary-data marker.

### Find potential deals

- A dedicated **Deals** tab highlights discounted items in your saved scan data.
- Filter by item name, market percentage, estimated profit, price age and available history.
- Browse deals by category or favorites.
- Inspect the assumed resale price, auction-house fee and potential profit in a separate details window.
- Open an exact-item search in Buy directly from a deal.

### Plan your shopping

- Set target quantities using your existing shopping lists.
- Compare wanted quantities against your bag contents and optionally your last recorded bank contents.
- See how many items you still need.
- Estimate the remaining cost using saved prices.
- Add items to shopping lists directly from the offline browser.

### Keep track of your activity

- Review recorded purchases and auction postings in **Trading Logs**.
- Filter by item name, activity, period and character.
- Sort records and view totals for the selected filters.
- Track purchases during the current auction-house visit, including quantities and spending across sellers.

### A rebuilt full-scan experience

- Process fast-scan data in small batches across frames.
- Remove the old CPU busy loop and duplicate name-based price processing.
- Prepare price history before publishing the database update.
- Follow progress on separate lines for auction counts, elapsed time and estimated time remaining.
- See a smoothed time estimate during slow scans.
- Choose **Stop and save**, **Keep scanning** or **Discard scan**.
- Save completed slow-scan pages without waiting for the entire scan to finish.
- Get clear timeouts and bounded retries instead of indefinite waiting.
- Receive a formatted chat summary with item changes and color-coded quality counts.

### A new database foundation

- Store prices by **item ID and suffix**, keeping distinct item variants separate.
- Keep market data separated by realm and faction.
- Separate learned names, icons and categories from actual price observations.
- Use cached calculations and bounded history storage.
- Include a metadata-only item catalog to supplement item information.
- Clear the current market database with confirmation and a session-only Undo option.

### Interface and everyday improvements

- Built-in **ElvUI integration**, alongside support for the standard WoW interface.
- Consistent styling for the browser, Deals, Logs and scan controls.
- Alternating list rows, clearer sorting indicators and improved column spacing.
- Movable auction-house window and detachable deal details.
- Shift-click bag items into searches in Deals, Logs and the Offline Browser.
- Shift-click bag items into the selling pane while Sell is open.
- Minimap access to the Offline Browser.
- Shift-right-click the minimap button to open database settings.
- Built-in seller information and merchant pricing, without requiring Auctionator MiniFeatures.
- Startup conflict detection for other enabled Auctionator versions and MiniFeatures.

## Screenshots

| Offline Browser | Price history |
| --- | --- |
| ![Offline Browser](screenshots/offline-browser.webp) | ![Price history](screenshots/price-history.webp) |

| Buy | Sell |
| --- | --- |
| ![Buy](screenshots/buy.webp) | ![Sell](screenshots/sell.webp) |

| Deals | Trading Logs |
| --- | --- |
| ![Deals](screenshots/deals.webp) | ![Trading Logs](screenshots/trading-logs.webp) |

| Full Scan |
| --- |
| <img src="screenshots/full-scan.webp" alt="Full Scan" width="400"> |

## Installation

1. Close WoW completely.
2. Download the **installation ZIP** from [Releases](https://github.com/andreash-dev/Auctionator-Remastered-WotLK/releases). Choose the addon ZIP attached to a release, rather than GitHub's automatic source-code archives.
3. Extract both addon folders into `World of Warcraft/Interface/AddOns/`:
   - `AuctionatorRemastered`
   - `AuctionatorRemastered_Startup`
4. Disable other Auctionator versions and Auctionator MiniFeatures.
5. Start WoW and enable both Remastered components. Enable **Load out of date AddOns** if needed.

Both folders belong to the same addon and are required. Do not rename them.

If another Auctionator version is enabled, the startup dialog lets you choose which version to use. It does not delete addon files or saved data.

## Updating

Close WoW, back up your addon folders and `WTF` directory, then replace **both Remastered addon folders** with the new versions.

**Existing data from the new Remastered database is preserved.**

Installing from original Auctionator, another fork, or an older release using the `Auctionator` folder starts a **fresh Remastered price database**. Legacy databases are not imported, and their saved files are left untouched. Do not rename old SavedVariables files to migrate them.

## Getting started

Visit the auction house and run a fast or slow **Full Scan** to collect prices. Open the Offline Browser through the minimap button or:

```text
/atr browse
```

Price history builds as you collect observations over time. Deals may initially be empty until enough history is available for your selected filters.

Items with missing categories or equipment slots are hidden by default. Enable **Show incomplete items** under **Interface → AddOns → Auctionator → Offline Browser** to include them.

## Warmane — fast-scan disconnects

On Warmane, fast scans can occasionally end with the server disconnecting you. In our testing, this appears to be a server-side issue: fast scans often start working again later without changing the addon.

If it happens, try again later. **Slow scan** is also available if you want to collect prices in the meantime.

## Compatibility and feedback

- Intended for the **3.3.5a client**.
- The standard WoW interface uses a warm anthracite theme; ElvUI retains its integrated styling.

Please [report issues](https://github.com/andreash-dev/Auctionator-Remastered-WotLK/issues) with reproduction steps, your UI setup, a screenshot and any Lua error.

## Credits

**Developed by Nisho. Based on the original Auctionator by Zirco (Thunderhorn US).**

Original contributor attribution is retained in [CREDITS.md](AuctionatorRemastered/CREDITS.md).
