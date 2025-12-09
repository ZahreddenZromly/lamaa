import 'package:flutter/material.dart';

/// Simple localization helper for EN / AR.
/// Only controls *texts*, not layout direction.
class S {
  final Locale locale;

  S(this.locale);

  bool get isArabic => locale.languageCode == 'ar';

  // ---------------------------------------------------------------------------
  // Access helpers
  // ---------------------------------------------------------------------------
  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S(const Locale('en'));
  }

  /// This is what main.dart expects: `S.delegate`
  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// List of supported locales (optional convenience)
  static const supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  // ---------------------------------------------------------------------------
  // GLOBAL / HOME STRINGS
  // ---------------------------------------------------------------------------

  String get appName => isArabic ? 'لمعة الإتقان' : 'Lamaa Cleaning';

  String get welcomeTitle => isArabic ? 'أهلاً بك 👋' : 'Welcome 👋';

  String get welcomeSubtitle => isArabic
      ? 'احجز خدمة التنظيف في ثوانٍ'
      : 'Book your cleaning service\nin a few clicks';

  String get latestNews => isArabic ? 'آخر الأخبار' : 'Latest news';

  String get homeTapServiceHint => isArabic
      ? 'اضغط على أي خدمة بالأسفل للحجز.'
      : 'Tap any service card below to make a reservation.';

  String errorLoadingServices(String msg) => isArabic
      ? 'حدث خطأ أثناء تحميل الخدمات:\n$msg'
      : 'Error loading services:\n$msg';

  String get noServicesAvailable =>
      isArabic ? 'لا توجد خدمات متاحة حالياً.' : 'No services available yet.';

  String errorLoadingNews(String msg) => isArabic
      ? 'حدث خطأ أثناء تحميل الأخبار: $msg'
      : 'Error loading news: $msg';

  String get topServiceLabel => isArabic ? 'خدمة مميزة' : 'Top service';

  String get detailsButton => isArabic ? 'التفاصيل' : 'Details';

  // ---------------------------------------------------------------------------
  // Static convenience helpers (for calls like S.appNameText(context))
  // ---------------------------------------------------------------------------

  static String appNameText(BuildContext context) => S.of(context).appName;

  static String welcomeTitleText(BuildContext context) =>
      S.of(context).welcomeTitle;

  static String welcomeSubtitleText(BuildContext context) =>
      S.of(context).welcomeSubtitle;

  static String latestNewsText(BuildContext context) =>
      S.of(context).latestNews;

  // ---------------------------------------------------------------------------
  // DRAWER / COMMON NAV
  // (you already use inline Arabic/English there, so optional)
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // CHANGE PASSWORD PAGE
  // ---------------------------------------------------------------------------

  String get changePasswordTitle =>
      isArabic ? 'تغيير كلمة المرور' : 'Change password';

  String get changePasswordHeading =>
      isArabic ? 'تحديث كلمة المرور' : 'Update your password';

  String get changePasswordDescription => isArabic
      ? 'لأمانك، يرجى إدخال كلمة المرور الحالية واختيار كلمة مرور جديدة.'
      : 'For your security, please enter your current password and choose a new one.';

  String get currentPasswordLabel =>
      isArabic ? 'كلمة المرور الحالية' : 'Current password';

  String get newPasswordLabel =>
      isArabic ? 'كلمة المرور الجديدة' : 'New password';

  String get confirmNewPasswordLabel =>
      isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm new password';

  String get saveNewPasswordButton =>
      isArabic ? 'حفظ كلمة المرور الجديدة' : 'Save new password';

  String get sendResetEmailInstead =>
      isArabic ? 'إرسال بريد لإعادة التعيين بدلاً من ذلك' : 'Send reset email instead';

  String get fillAllFieldsError =>
      isArabic ? 'يرجى ملء جميع الحقول.' : 'Please fill all fields.';

  String get newPasswordTooShortError => isArabic
      ? 'يجب أن تتكون كلمة المرور الجديدة من 6 أحرف على الأقل.'
      : 'New password must be at least 6 characters.';

  String get passwordsDontMatchError => isArabic
      ? 'كلمة المرور الجديدة وتأكيدها غير متطابقين.'
      : 'New password and confirmation do not match.';

  String get passwordUpdatedSuccess =>
      isArabic ? 'تم تحديث كلمة المرور بنجاح 🎉' : 'Password updated successfully 🎉';

  String get currentPasswordIncorrect =>
      isArabic ? 'كلمة المرور الحالية غير صحيحة.' : 'Current password is incorrect.';

  String get weakPasswordError =>
      isArabic ? 'كلمة المرور الجديدة ضعيفة جداً.' : 'The new password is too weak.';

  String get requiresRecentLoginError => isArabic
      ? 'لأسباب أمنية، يرجى تسجيل الخروج ثم تسجيل الدخول مرة أخرى، وبعدها حاول تغيير كلمة المرور.'
      : 'For security reasons, please log out and log in again, then try changing the password.';

  String get failedToChangePassword =>
      isArabic ? 'فشل تغيير كلمة المرور.' : 'Failed to change password.';

  String resetEmailSent(String email) => isArabic
      ? 'تم إرسال رسالة إعادة تعيين كلمة المرور إلى $email. يرجى التحقق من بريدك.'
      : 'Password reset email sent to $email. Check your inbox.';

  String sendResetEmailError(String msg) => isArabic
      ? 'حدث خطأ أثناء إرسال بريد إعادة التعيين: $msg'
      : 'Error sending reset email: $msg';

  String genericError(String msg) => isArabic ? 'خطأ: $msg' : 'Error: $msg';

  // ---------------------------------------------------------------------------
  // MY ORDERS PAGE
  // ---------------------------------------------------------------------------

  String get myOrdersTitle => isArabic ? 'طلباتي' : 'My orders';

  String errorLoadingOrders(String msg) => isArabic
      ? 'حدث خطأ أثناء تحميل الطلبات:\n$msg'
      : 'Error loading orders:\n$msg';

  String get noOrdersYet =>
      isArabic ? 'ليس لديك أي طلبات حتى الآن.' : 'You don’t have any orders yet.';

  String get statusConfirmed => isArabic ? 'مؤكد' : 'Confirmed';

  String get statusCompleted => isArabic ? 'مكتمل' : 'Completed';

  String get statusRejected => isArabic ? 'مرفوض' : 'Rejected';

  String get statusPending => isArabic ? 'قيد المراجعة' : 'Pending';

  String get notSet => isArabic ? 'غير محدد' : 'Not set';

  String get visitPrefix => isArabic ? 'الزيارة: ' : 'Visit: ';

  String get createdPrefix => isArabic ? 'تاريخ الإنشاء: ' : 'Created: ';

  String get currencySuffix =>
      isArabic ? ' د.ل' : ' LYD';


  String get rateServiceTitle =>
      isArabic ? 'قيّم هذه الخدمة' : 'Rate this service';

  String get adminCommentLabel =>
      isArabic ? 'ملاحظة للإدارة (اختياري)' : 'Comment for the admin (optional)';

  String get adminCommentHint =>
      isArabic ? 'هذه الملاحظة تظهر فقط لفريق الإدارة.' : 'This comment is only visible to the admin team.';

  String get cancelButton => isArabic ? 'إلغاء' : 'Cancel';

  String get submitButton => isArabic ? 'إرسال' : 'Submit';

  String get pleaseSelectStarRating =>
      isArabic ? 'يرجى اختيار تقييم بالنجوم.' : 'Please select a star rating.';

  String get rateButtonLabel => isArabic ? 'قيّم' : 'Rate';

  // ---------------------------------------------------------------------------
  // PROFILE PAGE
  // ---------------------------------------------------------------------------

  String get editProfileTitle =>
      isArabic ? 'تعديل البيانات الشخصية' : 'Edit personal details';

  String get fullNameLabel =>
      isArabic ? 'الاسم الكامل' : 'Full name';

  String get phoneNumberLabel =>
      isArabic ? 'رقم الهاتف' : 'Phone number';

  String get locationLabel =>
      isArabic ? 'الموقع / العنوان' : 'Location / Address';

  String get locationDescriptionLabel =>
      isArabic ? 'وصف الموقع (اختياري)' : 'Location description (optional)';

  String get locationDescriptionHint => isArabic
      ? 'رقم الشقة، العلامات المميزة، إلخ.'
      : 'Apartment number, landmarks, etc.';

  String get genderLabel =>
      isArabic ? 'النوع' : 'Gender';

  String get genderMale =>
      isArabic ? 'ذكر' : 'Male';

  String get genderFemale =>
      isArabic ? 'أنثى' : 'Female';

  String get genderOther =>
      isArabic ? 'آخر' : 'Other';

  String get profileRequiredFieldsError => isArabic
      ? 'يرجى إدخال الاسم، رقم الهاتف والموقع على الأقل.'
      : 'Please fill at least name, phone and location.';

  String get profileUpdated =>
      isArabic ? 'تم تحديث البيانات الشخصية' : 'Profile updated';

  String get saveProfileButton =>
      isArabic ? 'حفظ البيانات الشخصية' : 'Save personal details';

  String get savingProfileText =>
      isArabic ? 'جاري الحفظ...' : 'Saving...';

}

/// The delegate that plugs S into Flutter localization system
class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async {
    // no async work, just create S
    return S(locale);
  }

  @override
  bool shouldReload(_SDelegate old) => false;
}
