# Fix Database Initialization Error in TDLib Example

The app is currently failing to initialize TDLib because it attempts to create a database directory in a read-only location. This plan updates the app to use the application's documents directory provided by `path_provider`.

## Proposed Changes

### [example](file:///C:/Users/PC NET/Downloads/tdlib-master/tdlib-master/example/)

#### [MODIFY] [main.dart](file:///C:/Users/PC NET/Downloads/tdlib-master/tdlib-master/example/lib/main.dart)

1.  **Add Import**: Include `package:path_provider/path_provider.dart`.
2.  **Initialize Directory Path**:
    *   Declare a global `late String appDirectoryPath;`.
    *   Update `main()` to be `async` (already is).
    *   Ensure `WidgetsFlutterBinding.ensureInitialized();` is called (already is).
    *   Fetch the application documents directory using `getApplicationDocumentsDirectory()`.
    *   Store the path in `appDirectoryPath`.
3.  **Update TDLib Parameters**:
    *   Locate `_sendTdlibParameters()`.
    *   Update `databaseDirectory` to `"$appDirectoryPath/tdlib/"`.
    *   Update `filesDirectory` to `"$appDirectoryPath/tdlib/files/"`.
    *   Remove the `const` keyword from `SetTdlibParameters` since it now uses a dynamic string.

## Verification Plan

### Manual Verification
*   Confirm the code builds without errors.
*   The user will need to run the app to verify that the "Read-only file system" error is resolved and TDLib initializes correctly.
