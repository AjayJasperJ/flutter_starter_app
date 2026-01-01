# 🌐 Network Architecture Guide

This directory contains a **Resilient, Offline-First, Interceptor-Driven** network layer designed for high-performance production applications.

## 🏗️ Architecture Overview

The network layer is built on three main pillars:
1.  **Resilience**: Built-in retries, connectivity awareness, and persistent mutation queuing.
2.  **Performance**: SWR (Stale-While-Revalidate), **Session-Aware Caching**, JSON Isolates (background parsing), and Request Deduplication.
3.  **Developer Experience (DX)**: Sliver-powered UI builders and a unified side-effect notifier.

---

## 🛠️ Core Components

### 1. [ApiClient](file:///home/ja5p3r/products/my_app/lib/network/api_services/api_client.dart)
The central engine of the network layer. It manages:
- **Dio Instance**: Configured with professional timeouts and base headers.
- **Persistent Refresh Registry**: Tracks pages viewed while offline and auto-heals them upon reconnection.
- **Request Deduplication**: Merges identical in-flight requests to save bandwidth.

### 2. Interceptor Pipeline
Requests pass through a chain of specialized interceptors:
- **[AuthInterceptor](file:///home/ja5p3r/products/my_app/lib/network/interceptors/auth_interceptor.dart)**: Handles JWT injection and automatic 401 token refreshing.
- **[CacheInterceptor](file:///home/ja5p3r/products/my_app/lib/network/interceptors/cache_interceptor.dart)**: Implements **30-Day TTL** and **LRU Eviction (200 items)**.
- **[OfflineSyncInterceptor](file:///home/ja5p3r/products/my_app/lib/network/interceptors/offline_sync_interceptor.dart)**: Queues mutations (POST/PUT/DELETE) locally when offline.
- **[PerformanceInterceptor](file:///home/ja5p3r/products/my_app/lib/network/interceptors/performance_interceptor.dart)**: Logs metrics including Payload Size, TTFB, and Cache Status.

### 3. [UiBuilder (Sliver-Powered)](file:///home/ja5p3r/products/my_app/lib/network/notifiers/ui_builder.dart)
A declarative widget for rendering network states inside `CustomScrollView`.
- **States**: `idle`, `loading`, `success`, `failure`, `exception`, and `refreshing`.
- **Refreshing State**: Supports background updates without hiding existing data.
- **Shimmer Integration**: Works perfectly with `SliverShimmerList` and `SliverShimmerGrid`.

### 4. [UiBuilderLite (Standard)](file:///home/ja5p3r/products/my_app/lib/network/notifiers/ui_builder_lite.dart)
The regular version of `UiBuilder` for components like Cards or Headers that are not part of a scroll view. Returns a single `Widget`.

---

## 🚀 Key Production Features

### 📡 Stale-While-Revalidate (SWR)
When a `get` request is made, `ApiClient` returns cached data **instantly** (0ms lag) while fetching fresh data in the background. Once the network call completes, it updates the cache and notifies the UI.

### 🧵 Background JSON Parsing
To prevent UI jank, all JSON decoding for GET requests happens on a **Dart Isolate** via the `compute` function. This keeps the main thread at 60fps even when loading 1MB+ payloads.

### 🔄 Durable Auto-Recovery
The `refresh_queue` is stored in **Hive**. If a user closes the app while offline, their viewed-page-registry persists. Upon re-opening with internet, the app "heals" its cache automatically.

---

## 📖 Usage Examples

### 1. Fetching Data with SWR
```dart
final result = await apiClient.get('/profile', staleWhileRevalidate: true);
```

### 2. Building a Premium Sliver List
```dart
UiBuilder<List<User>>(
  response: userState,
  onLoading: () => [const SliverShimmerList(itemCount: 5)],
  onSuccess: (users) => [UserSliverList(users)],
  onRefreshing: (users) => [
    const SliverToBoxAdapter(child: LinearProgressIndicator()),
    UserSliverList(users),
  ],
)
```

### 3. Building a Regular Component (Non-Sliver)
```dart
UiBuilderLite<User>(
  response: profileResponse,
  onLoading: () => const ShimmerCard(),
  onSuccess: (user) => UserCard(user),
)
```

### 4. Performing an Action with Haptics & Toasts
```dart
updateNotifier(
  context,
  response: updateResponse,
  enableHaptics: true,
  todo: (state) {
    if (state == States.success) context.pop();
  },
);
```

---

## 📦 Persistence Layer (Hive Boxes)
| Box Name | Purpose |
| :--- | :--- |
| `api_cache` | Stores GET response data with timestamps. |
| `offline_queue` | Stores pending mutations for sync. |
| `refresh_queue` | Stores paths needing re-validation after offline use. |

---

## 🧪 Developer Guidelines
1.  **Be Sliver-First**: Always return slivers from `onSuccess` in `UiBuilder`.
2.  **Explicit Auth**: Map `withAuth: true` (default) if the endpoint requires a token.
3.  **Background Ready**: Rely on `updateNotifier` for all side-effects like navigation or toasts.
