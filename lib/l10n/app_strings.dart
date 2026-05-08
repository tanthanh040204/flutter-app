import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_language_provider.dart';

extension AppStringsX on BuildContext {
  AppStrings get tr => watch<AppLanguageProvider>().strings;
  AppStrings get readTr => read<AppLanguageProvider>().strings;
}

extension AppLanguageProviderStrings on AppLanguageProvider {
  AppStrings get strings => AppStrings(language);
}

class AppStrings {
  final AppLanguage _language;

  const AppStrings(this._language);

  bool get vi => _language == AppLanguage.vi;

  String get appTitle => 'UTE-go';
  String get moneyLocale => 'vi_VN';
  String get moneySymbol => 'đ';
  String get vietnamese => 'Tiếng Việt';
  String get english => 'English';
  String get language => vi ? 'Ngôn ngữ' : 'Language';
  String get languageSubtitle => vi ? 'Chọn ngôn ngữ hiển thị của ứng dụng' : 'Choose the app display language';
  String get home => vi ? 'Trang chủ' : 'Home';
  String get stations => vi ? 'Trạm xe' : 'Stations';
  String get rideStats => vi ? 'Thông số' : 'Ride data';
  String get notifications => vi ? 'Thông báo' : 'Notifications';
  String get more => vi ? 'Mở rộng' : 'More';
  String get priceList => vi ? 'Bảng giá' : 'Pricing';
  String get logout => vi ? 'Đăng xuất' : 'Log out';
  String get accountLocked => vi ? 'Tài khoản đã bị khóa' : 'Account locked';

  String get login => vi ? 'Đăng nhập' : 'Log in';
  String get register => vi ? 'Đăng ký' : 'Register';
  String get createAccount => vi ? 'Tạo tài khoản' : 'Create account';
  String get fullName => vi ? 'Họ và tên' : 'Full name';
  String get phoneNumber => vi ? 'Số điện thoại' : 'Phone number';
  String get password => vi ? 'Mật khẩu' : 'Password';
  String get confirmPassword => vi ? 'Xác nhận mật khẩu' : 'Confirm password';
  String get showPassword => vi ? 'Hiện mật khẩu' : 'Show password';
  String get hidePassword => vi ? 'Ẩn mật khẩu' : 'Hide password';
  String get demoUserName => vi ? 'Người dùng UTE-GO' : 'UTE-GO User';
  String get loginHint => vi ? 'Nhập email và mật khẩu đã đăng ký để đăng nhập.' : 'Enter your registered email and password to log in.';
  String get registerHint => vi ? 'Đăng ký cần họ tên, email, mật khẩu, xác nhận mật khẩu và số điện thoại.' : 'Registration requires full name, email, password, password confirmation, and phone number.';
  String get invalidEmail => vi ? 'Vui lòng nhập email hợp lệ.' : 'Please enter a valid email.';
  String get phoneRequired => vi ? 'Đăng ký bắt buộc phải có số điện thoại.' : 'Phone number is required for registration.';
  String get passwordRequired => vi ? 'Vui lòng nhập mật khẩu.' : 'Please enter your password.';
  String get confirmPasswordRequired => vi ? 'Vui lòng nhập xác nhận mật khẩu.' : 'Please confirm your password.';
  String get passwordMinLength => vi ? 'Mật khẩu phải có ít nhất 6 ký tự.' : 'Password must be at least 6 characters.';
  String get passwordMismatch => vi ? 'Mật khẩu xác nhận không khớp.' : 'Password confirmation does not match.';

  String get changePassword => vi ? 'Đổi mật khẩu' : 'Change password';
  String get currentPassword => vi ? 'Mật khẩu hiện tại' : 'Current password';
  String get newPassword => vi ? 'Mật khẩu mới' : 'New password';
  String get saveNewPassword => vi ? 'Lưu mật khẩu mới' : 'Save new password';
  String get processing => vi ? 'Đang xử lý...' : 'Processing...';
  String get passwordChanged => vi ? 'Đổi mật khẩu thành công.' : 'Password changed successfully.';

  String get onboardingTitle1 => vi ? 'Xe đạp công cộng - Đi bất kỳ đâu' : 'Public bikes - Go anywhere';
  String get onboardingDesc1 => vi ? 'Bạn có thể lấy xe tại một trạm, thực hiện chuyến đi và trả xe tại một trạm bất kỳ.' : 'Pick up a bike at one station, take your trip, and return it at any station.';
  String get onboardingTitle2 => vi ? 'Quét QR để mở khóa' : 'Scan QR to unlock';
  String get onboardingDesc2 => vi ? 'Chỉ cần quét QR trên xe và xác nhận sử dụng nếu số dư của bạn hợp lệ.' : 'Scan the QR code on the bike and confirm if your balance is valid.';
  String get onboardingTitle3 => vi ? 'Kết thúc chuyến đi' : 'End your trip';
  String get onboardingDesc3 => vi ? 'Đỗ xe tại trạm, khóa xe và xác nhận trả xe trên ứng dụng di động để kết thúc chuyến đi.' : 'Park at a station, lock the bike, and confirm return in the mobile app.';
  String get previous => vi ? 'Trước đó' : 'Previous';
  String get next => vi ? 'Tiếp theo' : 'Next';

  String hello(String name) => vi ? 'Xin chào, $name' : 'Hello, $name';
  String get balance => vi ? 'Số dư' : 'Balance';
  String get deposit => vi ? 'Tiền cọc' : 'Deposit';
  String get topUp => vi ? 'Nạp tiền' : 'Top up';
  String get scanQr => vi ? 'Quét QR' : 'Scan QR';
  String get enterRentalTime => vi ? 'Nhập thời gian thuê' : 'Enter rental time';
  String get rentalHoursLabel => vi ? 'Số giờ muốn thuê' : 'Rental hours';
  String get hourHint => vi ? 'Ví dụ: 1, 2, 3...' : 'Example: 1, 2, 3...';
  String get invalidHours => vi ? 'Vui lòng nhập số giờ hợp lệ.' : 'Please enter valid rental hours.';
  String selectedRentalHours(int hours) => vi ? 'Thời gian đã chọn: $hours giờ' : 'Selected duration: $hours hour(s)';
  String rentalFee(String amount) => vi ? 'Tiền thuê: $amount' : 'Rental fee: $amount';
  String depositFee(String amount) => vi ? 'Tiền cọc: $amount' : 'Deposit: $amount';
  String requiredTotal(String amount) => vi ? 'Tổng cần có: $amount' : 'Required total: $amount';
  String get noRideTitle => vi ? 'Hiện chưa có chuyến đi nào' : 'No active ride';
  String get noRideDesc => vi ? 'Bạn có thể nhập số giờ muốn thuê, nạp tiền và quét QR trên xe để bắt đầu sử dụng.' : 'Enter rental hours, top up, and scan the bike QR code to start riding.';
  String vehicleInUse(String name) => vi ? '$name đang được sử dụng' : '$name is in use';
  String get remainingTimeDesc => vi ? 'Thời gian còn lại được tính theo số giờ bạn đã nhập khi thuê xe.' : 'Remaining time is calculated from the hours you entered when renting.';
  String get resume => vi ? 'Tiếp tục' : 'Resume';
  String get pause => vi ? 'Tạm ngưng' : 'Pause';
  String get end => vi ? 'Kết thúc' : 'End';
  String get extendWarning => vi ? 'Bạn còn 15p sử dụng xe, vui lòng thuê thêm hoặc trả xe về trạm sớm nhất nhé!' : 'You have 15 minutes left. Please extend your ride or return the bike to a station soon.';
  String get returnStationWarning => vi ? 'Vui lòng trả xe về trạm' : 'Please return the bike to a station';

  String get scanQrUnlockTitle => vi ? 'Quét QR mở khóa xe' : 'Scan QR to unlock bike';
  String get invalidQr => vi ? 'QR không hợp lệ. App chỉ nhận QR có nội dung bắt đầu bằng "haq-trk-".' : 'Invalid QR. The app only accepts QR codes starting with "haq-trk-".';
  String vehicleNameFromCode(String code) => vi ? 'Xe $code' : 'Bike $code';
  String confirmUseVehicle(String vehicleName) => vi ? 'Bạn muốn sử dụng $vehicleName?' : 'Do you want to use $vehicleName?';
  String confirmRideEnoughBalance({required String vehicleId, required int hours, required String usageFee, required String depositAmount, required String requiredAmount}) {
    return vi
        ? 'Mã xe: $vehicleId\nBạn đã chọn $hours giờ.\nTiền thuê: $usageFee\nTiền cọc: $depositAmount\nTổng cần có: $requiredAmount'
        : 'Vehicle code: $vehicleId\nYou selected $hours hour(s).\nRental fee: $usageFee\nDeposit: $depositAmount\nRequired total: $requiredAmount';
  }
  String confirmRideNotEnoughBalance({required String vehicleId, required int hours, required String requiredAmount}) {
    return vi
        ? 'Mã xe: $vehicleId\nBạn đã chọn $hours giờ nhưng số dư hiện tại chưa đủ.\nTổng cần có: $requiredAmount'
        : 'Vehicle code: $vehicleId\nYou selected $hours hour(s), but your current balance is not enough.\nRequired total: $requiredAmount';
  }
  String get cancel => vi ? 'Hủy' : 'Cancel';
  String get yes => vi ? 'Có' : 'Yes';
  String startedRide(String vehicleName, int hours) => vi ? 'Đã bắt đầu thuê $vehicleName trong $hours giờ.' : 'Started renting $vehicleName for $hours hour(s).';
  String startRideFailed(String error) => vi ? 'Không thể bắt đầu chuyến đi: $error' : 'Could not start the ride: $error';

  String get notUsingBike => vi ? 'Bạn chưa sử dụng xe' : 'You are not using a bike';
  String get bikeLockedWaitingData => vi ? 'Xe đang khóa. App sẽ nhận dữ liệu khi ESP32 mở khóa.' : 'Bike is locked. The app will receive data after ESP32 unlocks.';
  String get bikeUnlockedWaitingData => vi ? 'Xe đã mở khóa, đang chờ ESP32 gửi dữ liệu...' : 'Bike is unlocked, waiting for ESP32 data...';
  String get battery => vi ? 'Pin' : 'Battery';
  String get temperature => vi ? 'Nhiệt độ' : 'Temperature';
  String get humidity => vi ? 'Độ ẩm' : 'Humidity';
  String get dust => vi ? 'Bụi' : 'Dust';
  String get status => vi ? 'Trạng thái' : 'Status';
  String get lockedTemporarily => vi ? 'Xe đang khóa tạm thời' : 'Bike temporarily locked';
  String get locked => vi ? 'Xe đang khóa' : 'Bike locked';
  String get unlocked => vi ? 'Xe đã mở khóa' : 'Bike unlocked';
  String get remainingTime => vi ? 'Thời gian còn lại' : 'Remaining time';
  String get overtimeFee => vi ? 'Phí quá giờ' : 'Overtime fee';
  String get resumeUse => vi ? 'Tiếp tục sử dụng' : 'Resume ride';
  String get pauseUse => vi ? 'Tạm ngưng sử dụng' : 'Pause ride';
  String get stopUse => vi ? 'Ngưng sử dụng' : 'Stop ride';

  String get refresh => vi ? 'Cập nhật' : 'Refresh';
  String get bikesAvailable => vi ? 'Xe còn' : 'Bikes';
  String get freeSlots => vi ? 'Chỗ trống' : 'Free slots';
  String get openGoogleMaps => vi ? 'Mở Google Maps' : 'Open Google Maps';
  String get bikesAtStation => vi ? 'Danh sách xe tại trạm' : 'Bikes at station';
  String bikeBatteryText(String status, int batteryPercent) => vi ? '$status - $batteryPercent% pin' : '$status - $batteryPercent% battery';

  String get routes => vi ? 'Lộ trình' : 'Routes';

  String get pricePerHour => vi ? 'Giá thuê 1 giờ' : 'Price per hour';
  String get minimumBalance => vi ? 'Số dư tối thiểu để bắt đầu' : 'Minimum balance to start';
  String get lowBatteryReturnThreshold => vi ? 'Ngưỡng pin nên trả xe' : 'Recommended return battery threshold';

  String get topUpByQr => vi ? 'Chuyển khoản theo QR bên dưới' : 'Transfer using the QR below';
  String get bank => vi ? 'Ngân hàng: UTE Bank' : 'Bank: UTE Bank';
  String get accountNumber => vi ? 'Số tài khoản: 0123456789' : 'Account number: 0123456789';
  String get accountName => vi ? 'Tên tài khoản: CONG TY UTE' : 'Account name: CONG TY UTE';
  String get topUpAmount => vi ? 'Số tiền cần nạp' : 'Top-up amount';
  String transferContent(String value) => vi ? 'Nội dung: $value' : 'Transfer content: $value';
  String get topUpCreated => vi ? 'Đã tạo yêu cầu nạp tiền.' : 'Top-up request created.';
  String get transferred => vi ? 'Tôi đã chuyển khoản' : 'I have transferred';

  String get extendRide => vi ? 'Thuê thêm' : 'Extend ride';
  String get extraHoursLabel => vi ? 'Số giờ muốn thuê thêm' : 'Extra hours';
  String extraHours(int hours) => vi ? 'Thời gian thêm: $hours giờ' : 'Extra time: $hours hour(s)';
  String extraFee(String amount) => vi ? 'Tiền cần trừ thêm: $amount' : 'Extra fee: $amount';
  String get confirmExtend => vi ? 'Xác nhận thuê thêm' : 'Confirm extension';
  String extendedRide(int hours) => vi ? 'Đã cộng thêm $hours giờ sử dụng.' : 'Added $hours hour(s) to your ride.';
}
