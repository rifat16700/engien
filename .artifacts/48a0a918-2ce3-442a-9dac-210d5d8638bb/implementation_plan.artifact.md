# Implementation Plan - Instant Zero-Second Loading & Permanent Cache

Implement a high-performance local caching layer for the chat list and message history to ensure the app loads instantly (0 seconds) without "fake waiting" or white screens, even before TDLib is fully connected.

## User Review Required

> [!IMPORTANT]
> - **Dart-side Cache**: Since TDLib initialization takes a few moments, I will add a secondary JSON-based cache on the Dart side. This allows the UI to show your conversations **immediately** upon app start.
> - **No Refetching**: Once data is loaded into the Provider, it stays there. We only fetch updates (new messages) instead of clearing and reloading everything.
> - **Chat History Persistence**: Messages for recently opened chats will also be cached, so entering a chat room shows previous messages instantly.

## Proposed Changes

### `example` Project

#### [MODIFY] [lib/providers/chat_provider.dart](file:///C:/src/tdlib-main/tdlib-master/example/lib/providers/chat_provider.dart)
- **State Persistence**:
    - Add `Future<void> loadFromCache()`: Reads a `cache.json` file from disk and populates the internal maps (`_chats`, `_messages`, `_mainChatIds`).
    - Add `Future<void> saveToCache()`: Periodically serializes the current state to JSON.
    - Implement a 2-second debounce for `saveToCache` to optimize performance.
- **Optimized Updates**:
    - Ensure `isInitialLoading` is set to `false` if the cache is found and not empty.

#### [MODIFY] [lib/main.dart](file:///C:/src/tdlib-main/tdlib-master/example/lib/main.dart)
- **Synchronous Init**: Call `chatProvider.loadFromCache()` in `main()` before `runApp`.
- This guarantees that the UI has data from the first frame.

#### [MODIFY] [lib/services/tdlib_service.dart](file:///C:/src/tdlib-main/tdlib-master/example/lib/services/tdlib_service.dart)
- **Auth Flow**: Ensure the transition from "initializing" to "authenticated" doesn't flicker or show a white screen.
- **Smart Loading**: Only trigger a "full" reload if the local cache is stale or empty.

#### [MODIFY] [lib/screens/chat_screen.dart](file:///C:/src/tdlib-main/tdlib-master/example/lib/screens/chat_screen.dart)
- **Instant Messages**: Immediately show cached messages from `TdChatProvider`.
- **Local History**: Call `GetChatHistory` with `onlyLocal: true` first to pull anything from the TDLib database without hitting the network.

## Verification Plan

### Manual Verification
- **Cold Start**: Close the app completely and reopen. Conversations must appear **instantly**.
- **Offline Mode**: Turn off the internet and open the app. You should still see your chat list and the last few messages of cached chats.
- **No White Screen**: Verify there is no "flash" of a white screen between the Auth and Home transition.
- **Persistence**: Send a message, close the app, reopen, and ensure that message is still visible without loading.
