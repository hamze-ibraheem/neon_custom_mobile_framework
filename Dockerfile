# Use a stable Dart image as the base
FROM dart:stable

# Set the working directory inside the container
WORKDIR /app

# Copy your custom SDK/framework files from the repo to the container
COPY . .

# Ensure your custom dart scripts are executable (if applicable)
# RUN chmod +x bin/your_custom_script.dart

# This keeps the container running so the "Console" stays active
CMD ["tail", "-f", "/dev/null"]