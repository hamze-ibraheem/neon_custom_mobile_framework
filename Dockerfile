# Use a stable Dart image as the base
FROM dart:stable

# Set the working directory inside the container
WORKDIR /app

# Copy your custom SDK/framework files from the repo to the container
COPY . .

# Setup the app
WORKDIR /app/NeonFramework-2/neon_framework/my_2nd_test_app
RUN dart pub get

# Run the app using the framework CLI
# Framework CLI is at ../bin/neon.dart
# App is at . (current workdir)
# Command: dart ../bin/neon.dart run -t web --release

CMD ["dart", "run", "neon_framework:neon", "run", "-t", "web", "--release"]