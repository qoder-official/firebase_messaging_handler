/// Fallback for non-web platforms where JS interop is unavailable.
F allowInterop<F extends Function>(F f) => f;

