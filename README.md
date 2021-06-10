# CombineAsyncually

This is a DEMONSTRATION of how you can bridge the new async / await functionality in Swift 5.5 with Combine.

There is NO WARRANTY. There is also a high chance this code may set your Mac, iPhone or other device on fire.

It provides three simple utilities that let you go mix and match your async functions and Combine publishers:

## Async Function to Combine

These samples use the `withPublisher`<sup>1</sup> and `withThrowingPublisher` functions to run an async closure and emit the result.

```swift
func myAsyncFunction() async -> String {
    return "Hello 👋"
}

// For non-throwing functions
withPublisher {
    await myAsyncFunction()
}
    .sink {
        print($0)   // Hello 👋
    }

// For throwing ones
withThrowingPublisher {
    try await someThrowingFunction()
}
    .catch {
        // handle error
    }
    .sink {
        // handle value
    }
```

## Mixing Async Functions in Combine Publisher chains

You can use the `.await` and `.tryAwait` operators to mix and match your Combine publishers and async code.

```swift
// Non throwing functions
somePublisher
    .await { value in 
        return await someAsyncFunction(value)
    }
    .sink {
        // handle result of someAsyncFunction
    }
    
// Throwing ones
somePublisher
    .tryAwait { value in
        return try await someThrowingAsyncFunction(value)
    }
    .catch {
        // handle error
    }
    .sink {
        // handle result of someAsyncFunction
    }
```

## Awaiting Your Publishers

You can also call `.get()` on supported Publishers<sup>2</sup> to await for the Publisher to complete.

```swift
let result1 = try await Just("Hello!").get()            // Hello!    
let result2 = try await somePublisher.first().get()
```

## Learning more

This repository is here to support a presentation given at Melbourne CocoaHeads on the 10th of June 2021. You can watch it [here](https://melbournecocoaheads.com/live).

### Notes

1. They're named to align with the [withTaskGroup] and [withThrowingTaskGroup] (and friends) functions.
2. We only support publishers that are guaranteed to emit once because this is just too dangerous. Use `.first()` to get around this.

[withTaskGroup]: https://developer.apple.com/documentation/swift/3814991-withtaskgroup/
[withThrowingTaskGroup]: https://developer.apple.com/documentation/swift/3814996-withthrowingtaskgroup
