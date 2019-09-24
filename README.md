# datomic

## Overview

The library wraps some primitive types (integer, boolean and pointer) as `object`s. Each has initializer `Init` that sets initial value and finalizer `Done`. Each has methods `SetValue`, `GetValue` and a property `Value`. There are some other useful methods like `Inc`, `CompareExchangeStrong` etc.

All public methods and properties are atomic (or thread-safe). Practically that means that other threads cannot see the data in partially-updated state while method is executing. (But the data can be changed by other threads between successive calls.)

Note that basically all methods need to block CPU and update CPU caches. So overusing atomic operations does not help to increase performance. Always measure performance of your application.

See [datomic.pas](datomic.pas) for details.
