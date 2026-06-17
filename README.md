# AsyncImageLib

A small Swift library for asynchronously loading, caching, and displaying remote
images on iOS, with ready-to-use UIKit and SwiftUI views. Two demo apps show the
library driving a scrollable image grid.

## Features

- **UIKit and SwiftUI views** - `AsyncImageView` (a `UIView`) and `AsyncImage`
  (a SwiftUI `View`), both showing a placeholder while loading.
- **Two-tier cache** - a fast in-memory layer (`NSCache`) backed by a persistent
  on-disk layer. Disk entries survive app restarts and expire after a
  configurable age (4 hours by default).
- **Request coalescing** - concurrent requests for the same URL share a single
  in-flight download, so an image is never fetched twice at once.
- **Reuse-safe** - starting a new load (or cancelling) drops any in-flight
  request, and a finished download is applied only if its URL still matches, so
  a recycled cell never shows a stale image.
- **Structured concurrency** - built on `async`/`await` and an `actor`-isolated
  loader; loads are cancelled automatically when a view disappears.

## Requirements

- iOS 15.6+
- Swift 5.0 / Xcode

## Architecture

```
AsyncImage (SwiftUI)   -|
                        |-->  AsyncImageLoader (actor)  -->  AsyncImageCacheManager
AsyncImageView (UIKit) -|                                   |- MemoryImageCache (NSCache)
                                                            |- DiskImageCache (files)
```

| Component                | Role                                                                                                                                 |
|--------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| `AsyncImageLoader`       | Singleton actor that resolves a URL through memory → disk → network, populating both cache layers and coalescing duplicate requests. |
| `AsyncImageCache`        | Protocol abstracting the cache; receives both the decoded `UIImage` and its encoded `Data` on store.                                 |
| `AsyncImageCacheManager` | Two-tier cache composing memory over disk.                                                                                           |
| `MemoryImageCache`       | Thread-safe in-memory cache backed by `NSCache`.                                                                                     |
| `DiskImageCache`         | Actor-isolated file-system cache with age-based expiration.                                                                          |
| `CacheKey`               | Stable key derived from a URL; a SHA-256 digest safe to use as a file name.                                                          |
| `AsyncImageView`         | UIKit view that loads and displays an image with a placeholder.                                                                      |
| `AsyncImage`             | SwiftUI view driven by `.task(id:)`.                                                                                                 |

## Usage

### SwiftUI

```swift
import SwiftUI

AsyncImage(url: imageURL) {
    ProgressView()          // shown while loading and on failure
}
.frame(height: 110)
.clipShape(RoundedRectangle(cornerRadius: 8))
```

### UIKit

```swift
let imageView = AsyncImageView()
imageView.imageContentMode = .scaleAspectFill
imageView.load(url: imageURL)

// In a reused cell:
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.cancelLoading()
}
```

### Loading directly

```swift
let image = try await AsyncImageLoader.shared.image(from: url)

// Drop both cache layers:
await AsyncImageLoader.shared.clearCache()
```

Both views accept a custom `AsyncImageLoader` if you need a separate cache or
`URLSession` instead of the shared singleton.

## Demo apps

The repository includes two example targets, `DemoUIKit` and `DemoSwiftUI`, each
rendering the same image grid on top of the library:

- A scrollable grid of remote images, each labelled with its id.
- A **Clear Cache** action that invalidates the cache and reloads.

By default the demos pull from the public
[`picsum.photos`](https://picsum.photos) list API, since no feed was specified
with the assignment. To use your own feed shaped as `[{ "id": ..., "url": ... }]`,
update `ImageEndpoint.imageList` and adjust `ImageItem` decoding in `DemoShared/`.

## Project layout

```
Library/        The reusable image-loading library
  Core/         AsyncImageLoader, ImageLoadingError
  Cache/        Cache protocol, manager, memory/disk layers, CacheKey
  AsyncImage*   UIKit and SwiftUI views
DemoShared/     Image-list service and model shared by both demos
DemoApp/        UIKit demo (DemoUIKit target)
DemoSwiftUI/    SwiftUI demo (DemoSwiftUI target)
```

## Building

Open `AsyncImageLib.xcodeproj` in Xcode and run the `DemoUIKit` or `DemoSwiftUI`
scheme on an iOS 15.6+ simulator or device.
