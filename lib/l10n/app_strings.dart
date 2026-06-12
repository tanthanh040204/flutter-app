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

  String get onboardingTitle1 => vi ? 'Phương tiện công cộng - Đi bất kỳ đâu' : 'Public vehicles - Go anywhere';
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
  String get debt => vi ? 'Tiền nợ' : 'Debt';
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
  String get connectingBle =>
      vi ? 'Đang kết nối Bluetooth…' : 'Connecting via Bluetooth…';
  String get bleScanning => vi ? 'Bluetooth: đang tìm xe' : 'BLE: scanning for bike';
  String get bleConnecting => vi ? 'Bluetooth: đang kết nối' : 'BLE: connecting';
  String get bleRelaying => vi ? 'Bluetooth đang truyền dữ liệu' : 'BLE relay active';
  String startedRide(String vehicleName, int hours) => vi ? 'Đã bắt đầu thuê $vehicleName trong $hours giờ.' : 'Started renting $vehicleName for $hours hour(s).';
  String startRideFailed(String error) => vi ? 'Không thể bắt đầu chuyến đi: $error' : 'Could not start the ride: $error';

  String get notUsingBike => vi ? 'Bạn chưa sử dụng xe' : 'You are not using a bike';
  String get bikeLockedWaitingData => vi ? 'Xe đang khóa. App sẽ nhận dữ liệu khi ESP32 mở khóa.' : 'Bike is locked. The app will receive data after ESP32 unlocks.';
  String get bikeUnlockedWaitingData => vi ? 'Xe đã mở khóa, đang chờ ESP32 gửi dữ liệu...' : 'Bike is unlocked, waiting for ESP32 data...';
  String get battery => vi ? 'Pin' : 'Battery';
  String get temperature => vi ? 'Nhiệt độ' : 'Temperature';
  String get humidity => vi ? 'Độ ẩm' : 'Humidity';
  String get dust => vi ? 'Bụi' : 'Dust';
  String get speed => vi ? 'Vận tốc' : 'Speed';
  String get distanceTraveled => vi ? 'Quãng đường đã đi' : 'Distance traveled';
  String get dangerNoti => vi ? 'Cảnh báo nguy hiểm' : 'Danger alerts';
  String get findVehicle => vi ? 'Tìm xe' : 'Find bike';
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

  String get dailyBriefingTitle => vi ? 'Tin giao thông & thời tiết hôm nay' : 'Today traffic & weather';
  String dailyBriefingSubtitle(String date) => vi
      ? 'Cập nhật mỗi ngày • $date'
      : 'Updated daily • $date';
  String get loadingDailyNews => vi ? 'Đang tải bản tin mới...' : 'Loading latest updates...';
  String get liveUpdated => vi ? 'Tin mới từ nguồn online' : 'Live from online source';
  String get dailyUpdated => vi ? 'Gợi ý thay đổi theo ngày' : 'Daily rotating tip';
  String get readMore => vi ? 'Đọc thêm' : 'Read more';
  String get traffic => vi ? 'Giao thông' : 'Traffic';
  String get weather => vi ? 'Thời tiết' : 'Weather';
  String get openTrafficNews => vi ? 'Tin giao thông' : 'Traffic news';
  String get openWeatherForecast => vi ? 'Dự báo thời tiết' : 'Weather forecast';
  String get noticeOfferTitle => vi ? 'Thông báo & ưu đãi hôm nay' : 'Today notices & offers';

  String get usageGuideTitle => vi ? 'Hướng dẫn sử dụng' : 'How to use';
  String get usageGuideCardDesc => vi
      ? 'Xem nhanh các bước thuê xe, quét QR, theo dõi chuyến đi và trả xe.'
      : 'Quick steps for renting, scanning QR, tracking your ride, and returning the bike.';
  String get usageGuideIntro => vi
      ? 'Làm theo các bước dưới đây để thuê xe đúng quy trình và tránh lỗi phát sinh không đáng có.'
      : 'Follow these steps to rent a bike correctly and avoid unnecessary errors.';
  String get usageGuideTip => vi
      ? 'Mẹo nhỏ: trước khi quét QR, hãy kiểm tra số dư, thời gian thuê, pin xe và trạm trả xe. Bốn việc nhỏ, bớt được một đống phiền phức.'
      : 'Tip: before scanning QR, check your balance, rental time, bike battery, and return station. Four small checks, fewer problems.';
  String get guideStepLoginTitle => vi ? 'Đăng nhập hoặc đăng ký' : 'Log in or register';
  String get guideStepLoginBody => vi
      ? 'Dùng email và mật khẩu để đăng nhập. Nếu chưa có tài khoản, đăng ký bằng họ tên, email, mật khẩu và số điện thoại.'
      : 'Use your email and password to log in. If you do not have an account, register with your name, email, password, and phone number.';
  String get guideStepTopUpTitle => vi ? 'Nạp tiền vào ví' : 'Top up your wallet';
  String get guideStepTopUpBody => vi
      ? 'Vào nút Nạp tiền, chuyển khoản theo thông tin QR và chờ hệ thống ghi nhận số dư.'
      : 'Tap Top up, transfer using the QR information, and wait for the balance to be recorded.';
  String get guideStepTimeTitle => vi ? 'Chọn thời gian thuê' : 'Choose rental time';
  String get guideStepTimeBody => vi
      ? 'Nhập số giờ muốn thuê. App sẽ tính tiền thuê, tiền cọc và tổng số dư cần có.'
      : 'Enter the number of rental hours. The app calculates the rental fee, deposit, and required total.';
  String get guideStepQrTitle => vi ? 'Quét QR trên xe' : 'Scan the bike QR';
  String get guideStepQrBody => vi
      ? 'Bấm Quét QR và chỉ quét mã hợp lệ bắt đầu bằng “haq-trk-”. Sau khi xác nhận, app gửi lệnh mở khóa đến phần cứng.'
      : 'Tap Scan QR and scan only valid codes starting with “haq-trk-”. After confirmation, the app sends an unlock command to the device.';
  String get guideStepRideTitle => vi ? 'Theo dõi chuyến đi' : 'Track your ride';
  String get guideStepRideBody => vi
      ? 'Trong lúc sử dụng, bạn có thể xem thời gian còn lại, trạng thái xe và dữ liệu xe gửi về.'
      : 'During the ride, you can view remaining time, bike status, and live data from the device.';
  String get guideStepReturnTitle => vi ? 'Trả xe và kết thúc' : 'Return and end ride';
  String get guideStepReturnBody => vi
      ? 'Đưa xe về trạm hợp lệ, khóa xe và bấm kết thúc sử dụng để hệ thống tính tiền chuyến đi.'
      : 'Return the bike to a valid station, lock it, and end the ride so the system can calculate the final fee.';


  String get bill => vi ? 'Hóa đơn' : 'Bill';
  String get userId => vi ? 'Mã người dùng' : 'User ID';
  String get endedAt => vi ? 'Thời gian kết thúc' : 'Ended at';
  String get totalAmount => vi ? 'Tổng tiền' : 'Total amount';
  String get close => vi ? 'Đóng' : 'Close';
  String get rideEndedTitle => vi ? 'Đã kết thúc chuyến đi' : 'Ride ended';
  String get rideCompletedSuccessfully => vi ? 'Hoàn tất thành công' : 'Completed successfully';
  String get rideEndedWarningTitle => vi ? 'Đã kết thúc chuyến đi (cảnh báo)' : 'Ride ended (warning)';
  String get rideGraceWindowStatus => vi ? 'Kết thúc trong thời gian cảnh báo 15 phút' : 'Ended within the 15-minute grace window';
  String get rideGraceWindowDetail => vi
      ? 'Bạn đã trả xe trong khoảng thời gian cảnh báo 15 phút.'
      : 'You returned the bike within the 15-minute warning window.';
  String get rideEndedViolationTitle => vi ? 'Đã kết thúc chuyến đi (vi phạm)' : 'Ride ended (violation)';
  String get ridePenaltyStatus => vi ? 'Vượt quá thời gian cảnh báo 15 phút' : 'Exceeded the 15-minute warning window';
  String get ridePenaltyDetail => vi
      ? 'Xe vẫn ở ngoài khu vực trả xe sau thời gian cảnh báo 15 phút. Hệ thống đã kết thúc chuyến đi và áp dụng phí phạt.'
      : 'The bike was still outside a parking zone after the 15-minute warning. The system ended the ride and applied a penalty.';

  String get ratePerHour => vi ? 'Giá thuê theo giờ' : 'Rate per hour';
  String get suggestedReturnBatteryThreshold => vi ? 'Ngưỡng pin khuyến nghị khi trả xe' : 'Suggested return battery threshold';

  String get topUpSuccessful => vi ? 'Nạp tiền thành công' : 'Top-up successful';
  String get topUpFailed => vi ? 'Nạp tiền thất bại' : 'Top-up failed';
  String newBalance(String amount) => vi ? 'Số dư mới: $amount' : 'New balance: $amount';
  String memo(String value) => vi ? 'Nội dung chuyển khoản: $value' : 'Memo: $value';
  String get saving => vi ? 'Đang lưu...' : 'Saving...';

  String vehicleLabel(String id) => vi ? 'Xe $id' : 'Bike $id';
  String get unlockingBike => vi ? 'Đang mở khóa xe...' : 'Unlocking the bike...';
  String pricePerHourAmount(int amount) => vi ? '$amountđ/giờ' : '$amountđ/hour';
  String get pauseDiscountSuffix => vi ? ' (giảm 50%)' : ' (50% off)';
  String overdueText(String value) => vi ? 'Quá hạn $value' : 'Overdue $value';
  String get balanceRunningLowTitle => vi ? 'Số dư sắp hết' : 'Balance running low';
  String get outOfBalanceTitle => vi ? 'Hết số dư — vui lòng trả xe' : 'Out of balance — return the bike';
  String get outOfParkingZoneTitle => vi ? 'Xe đang ngoài khu vực trả xe hợp lệ' : 'Outside a valid parking zone';
  String get warning => vi ? 'Cảnh báo' : 'Warning';
  String get lowBalanceBody => vi
      ? 'Bạn chỉ còn đủ tiền cho khoảng thời gian hiện tại. Vui lòng nạp thêm.'
      : 'You only have enough for the current block. Please top up.';
  String get outOfBalanceBody => vi
      ? 'Vui lòng trả xe về khu vực đỗ hợp lệ trong vòng 15 phút để tránh phí phạt.'
      : 'Return the bike to a parking zone within 15 minutes to avoid a penalty.';
  String get outOfParkingZoneBody => vi
      ? 'Di chuyển xe đến khu vực đỗ gần nhất để kết thúc chuyến đi.'
      : 'Move the bike to the nearest parking zone to end the ride.';
  String get couldNotStartRide => vi ? 'Không thể bắt đầu chuyến đi' : 'Could not start the ride';

  String get route => vi ? 'Lộ trình' : 'Route';
  String routeFromTo(String start, String end) => vi ? 'Lộ trình từ $start đến $end' : 'Route $start to $end';
  String routeAt(String start) => vi ? 'Lộ trình $start' : 'Route $start';

  String errorDescription(String code) {
    switch (code) {
      case 'ERR_ACCOUNT_INVALID':
        return vi ? 'Tài khoản không hợp lệ.' : 'Invalid account.';
      case 'ERR_USER_NOT_FOUND':
        return vi ? 'Không tìm thấy người dùng.' : 'User does not exist.';
      case 'ERR_ACCOUNT_DEBT':
        return vi ? 'Tài khoản còn phí chưa thanh toán.' : 'Account has outstanding fees.';
      case 'ERR_INSUFFICIENT_BALANCE':
        return vi ? 'Số dư không đủ để thuê xe.' : 'Balance is insufficient to rent.';
      case 'ERR_BIKE_UNAVAILABLE':
        return vi ? 'Xe hiện không khả dụng.' : 'Vehicle is not available.';
      case 'ERR_BIKE_IN_USE':
        return vi ? 'Xe đang được người khác sử dụng.' : 'Vehicle is currently in use by another rider.';
      case 'ERR_TIME_LIMIT_WARNING':
        return vi ? 'Bạn đã vượt thời gian cho phép, đang trong mức cảnh báo.' : 'You are over the allowed time (warning).';
      case 'ERR_TIME_LIMIT_EXCEEDED':
        return vi ? 'Đã vượt quá thời gian cho phép và bị tính phí phạt.' : 'Time limit exceeded — locked and penalised.';
      case 'ERR_OUT_OF_PARKING_ZONE':
        return vi ? 'Xe đang ở ngoài khu vực đỗ hợp lệ.' : 'Vehicle is outside a valid parking zone.';
      case 'ERR_TOPUP_AMOUNT_INVALID':
        return vi ? 'Số tiền nạp không hợp lệ.' : 'Invalid top-up amount.';
      case 'ERR_TOPUP_FAILED':
        return vi ? 'Nạp tiền thất bại.' : 'Top-up failed.';
      default:
        return vi ? 'Đã xảy ra lỗi ($code).' : 'An error occurred ($code).';
    }
  }

}
