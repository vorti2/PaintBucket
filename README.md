# PaintBucket

[![Travis branch](https://img.shields.io/travis/jflinter/PaintBucket/master.svg)]()

PaintBucket is pretty literally what its title suggests. It is an implementation of [Scanline Flood Fill](https://en.wikipedia.org/wiki/Flood_fill#Scanline_fill) in Swift, more commonly known as the algorithm that the paint bucket tool in MS Paint uses under the hood (well, it uses something like it, anyway).

This might, for example, be useful if you have a bunch of product photos shot against a uniformly-colored background and you want to remove said background. Or not, who knows.

## Usage
This library exposes a single new category method on `UIImage`:

```swift
let image = UIImage(named: "something")!
let imageWithoutBackground = image.pbk_imageByReplacingColorAt((0, 0), withColor: UIColor.clearColor(), tolerance: 10)
```

Its parameters should be self-explanatory.

## Performance
This is decently fast! That is to say, I was able to speed it up ~100x from my initial implementation (which admittedly was pretty slow). That said, it's not, like, instantaneous. You should probably do this on a background thread unless your images are *tiny*. (For reference, the 2000x1566 benchmark PNG takes like 3 seconds to process in the simulator on a MacBook pro).

Thanks to the always-amazing [Mike Ash](https://mikeash.com/pyblog/friday-qa-2012-09-14-implementing-a-flood-fill.html) for the idea to use an `NSIndexSet` for temporary storage, and thanks to [this random website I found](http://lodev.org/cgtutor/floodfill.html#Recursive_Scanline_Floodfill_Algorithm) for some implementation ideas for the scanline optimization. That said, this can almost certainly be faster, and I'd welcome a PR that made it so. There's a benchmark in the test suite you can run to see if your code helps.

## Contributing
PRs welcome - I'd ask that you open an issue before blindly sending PRs my way just to make sure we agree that your idea is a Good Thing. To get you started, if someone wants to add some kind of clever anti-aliasing to this, I'd sure love that.

## Installation
[Carthage](https://github.com/Carthage/Carthage): add `github "jflinter/PaintBucket", ~> 0.1` to your Cartfile.

[CocoaPods](cocoapods.com): add `pod 'PaintBucket', '~> 0.1'` to your Podfile.

![](http://i.giphy.com/scEmJ6yaTmhrO.gif)
