# CDK Directory Configuration

The CDK Swift bindings project uses the `CDK_DIR` environment variable to locate the CDK repository containing the `cdk-ffi` crate.

## Default Behavior

By default, the project expects the CDK repository to be located at `../cdk` relative to the cdk-swift project directory:

```
parent-directory/
├── cdk/                    # CDK repository
│   └── crates/cdk-ffi/    # FFI crate location
└── cdk-swift/             # This project
    ├── justfile
    └── ...
```

## Custom CDK Location

### Option 1: Environment Variable (Recommended)

Set the `CDK_DIR` environment variable to point to your CDK repository:

```bash
# Temporary (current session)
export CDK_DIR=/path/to/your/cdk

# Permanent (add to ~/.bashrc, ~/.zshrc, etc.)
echo 'export CDK_DIR=/path/to/your/cdk' >> ~/.bashrc
```

### Option 2: Per-Command Override

You can override the CDK directory for individual commands:

```bash
CDK_DIR=/custom/path/to/cdk just build-native
CDK_DIR=/custom/path/to/cdk just generate-bindings
```

## Validation

Check if your CDK directory is configured correctly:

```bash
# Check CDK directory configuration
just check-cdk

# Show current configuration
just info
```

Example output:
```
Checking CDK directory...
CDK_DIR = /Users/john/projects/cdk
✅ CDK directory exists
✅ CDK FFI crate found
```

## Supported Commands

All build and test commands respect the `CDK_DIR` environment variable:

**Build Commands:**
- `just build` - Full cross-platform build
- `just build-native` - Native-only build
- `just generate-bindings` - Generate Swift bindings
- `just build-rust` - Build Rust library
- `just clean` - Clean builds (including CDK target directory)

**Test Commands:**
- `just test-rust` - Test Rust library compilation

**Development Commands:**
- `just check-cdk` - Validate CDK directory setup
- `just info` - Show configuration information

## Setup Instructions

1. **Clone CDK repository:**
   ```bash
   git clone https://github.com/cashubtc/cdk.git
   ```

2. **Set environment variable:**
   ```bash
   export CDK_DIR=/path/to/cloned/cdk
   ```

3. **Verify setup:**
   ```bash
   just check-cdk
   ```

4. **Build the project:**
   ```bash
   just build-native
   ```

## Troubleshooting

### CDK Directory Not Found
```
❌ CDK directory not found at /path/to/cdk
```
**Solution:** Verify the path exists and contains the CDK repository.

### CDK FFI Crate Not Found
```
❌ CDK FFI crate not found in /path/to/cdk/crates/cdk-ffi
```
**Solution:** Ensure you have the complete CDK repository with all crates.

### Permission Issues
```
Permission denied: /path/to/cdk
```
**Solution:** Check directory permissions or use a path you have access to.