class ValidationMethods {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters long';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, or apostrophes';
    }
    return null;
  }

  static String? validateCountry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country is required';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Address must be at least 5 characters long';
    }
    if (!RegExp(r"^[a-zA-Z0-9\s,.-/#]+$").hasMatch(value)) {
      return 'Address contains invalid characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'field should not be empty';
    }
    if (value.length < 8) {
      return 'field must be at least 8 characters long';
    }
    return null;
  }

  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email or phone number';
    }

    final input = value.trim();

    // Reject emojis or unusual symbols
    // (Allows only letters, digits, @, ., -, _, and +)
    final validChars = RegExp(r'^[a-zA-Z0-9@.\-_\+]+$');
    if (!validChars.hasMatch(input)) {
      return 'Special characters or emojis are not allowed';
    }

    // Email and phone regex
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    final phoneRegex = RegExp(r'^[0-9]{10}$'); // Adjust for your format

    if (!emailRegex.hasMatch(input) && !phoneRegex.hasMatch(input)) {
      return 'Please enter a valid email address or 10-digit phone number';
    }

    return null; // valid
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one digit';
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$&*~)';
    }
    return null;
  }
}
