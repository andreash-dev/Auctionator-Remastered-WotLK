# Auctionator Remastered 1.0.0

The first stable release of **Auctionator Remastered**, developed by **Nisho** for **World of Warcraft 3.3.5a** and tested on **Warmane**. Based on Auctionator 3.1.5 by Zirco, it keeps the familiar buying and selling workflow while adding an offline browser, price history, deal discovery, shopping planning and trading logs.

## Your auction data, available anywhere

Open the **Offline Browser** without visiting the auction house. Search saved prices, explore expandable item categories and equipment slots, save favorites and inspect daily price-history charts. Compare the latest saved lowest price with a configurable **Market % reference**, and spot stale prices through the new age warning.

Prices and history remain separated by realm and faction, with item-ID/suffix identities keeping distinct variants apart. The included item catalog supplies metadata; it never seeds market prices.

## Find deals and plan your shopping

The **Deals** tab finds potential bargains in your saved scans. Filter by market percentage, estimated profit, price age and history coverage, then inspect resale assumptions and AH fees in the details window. Open an exact-item Buy search when you want to check current listings.

Use the **Shopping Planner** with your shared shopping lists to compare wanted quantities with bag contents and optional cached bank contents, see what is missing and estimate the remaining cost.

## Clearer material values for Enchanting and Jewelcrafting

Tooltips now show estimated **disenchant value** and **prospecting value per five ore**, using the latest saved lowest prices of the possible materials. Expand the breakdown to see gems, powders and enchanting materials with their chances, quantity ranges and lowest unit prices.

Both breakdowns have their own **Shift, Control, Alt, Always or Never** setting. Missing prices show **unknown** rather than an incomplete total. WotLK material tables are estimates; actual server drop rates may differ, and AH fees are not deducted from these values.

## Better purchase handling and Trading Logs

Batch buying now waits for acknowledgements and refreshed auction results, with confirmed progress, bounded waits and a **Buy next** click for each subsequent purchase. Recent Searches update immediately and keep the active item easy to find.

**Trading Logs** now support multiple selected characters, Today/7 days/30 days/All time, and custom **From/To dates**. Combine these with item-name and activity filters, review filtered totals, or use Reset filters to start over. Posting records describe listings, not confirmed sales.

## Standard WoW and ElvUI, with reviewed settings

Choose **Standard WoW or ElvUI styling** and control auction-house, Browser and Planner background transparency independently. Settings fit the original Interface options window, with aligned controls, explanatory hover help, readable Database status cards and consistent purchase/error dialogs.

The final UI pass also tidies Buy's toolbar, Sell's controls, sidebar highlights and scrollbars, empty-state messages and Browser/bag window layering.

New installations use **12-hour auctions**, **14-day Market comparison**, **30-day history retention**, and an **old-price warning after one day**. Full Scan chat summaries default on and completion sounds off. Lowering the history-retention limit requires confirmation. Existing valid saved preferences are preserved.

## Installation and updating

Download **Auctionator-Remastered-WotLK-1.0.0.zip** from the GitHub release assets. Close WoW completely, back up your addon folders and `WTF` directory, then replace **both** folders in `Interface/AddOns/`:

- `AuctionatorRemastered`
- `AuctionatorRemastered_Startup`

Disable other Auctionator versions and Auctionator MiniFeatures, then restart WoW. Existing Remastered data is preserved. Original Auctionator/fork databases are not imported; their saved files are left untouched.

## Known limitations and feedback

Offline prices and deal estimates do not guarantee current availability or profit. Purchases may still be rejected or time out; the cause of intermittent failures observed on Warmane is not confirmed. Check purchase results before retrying after a confirmation timeout. Fast scans can also occasionally disconnect on Warmane; slow scanning remains available.

[Full technical patch notes](https://github.com/andreash-dev/Auctionator-Remastered-WotLK/blob/main/RELEASE_CHANGELOG.md) · [Installation and features](https://github.com/andreash-dev/Auctionator-Remastered-WotLK#installation) · [Report an issue](https://github.com/andreash-dev/Auctionator-Remastered-WotLK/issues)
