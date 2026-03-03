import Foundation

extension String {
    public enum Regex: String {
        case password
        case username
        case phone
        case realName
        case otp
        case id
        case referrerCode
        case email
        case receiverRemark
        case weChat
        case address
        case securityQuestionAnswer
        case serialNumber
        case securityCode
        case bankAccountNumber
        case bankName
        case bankAddress
        case cryptoWalletName
        case cryptoWalletAddressTRC
        case cryptoWalletAddressERC
        case pureToken

        var value: String {
            switch self {
            case .password:
                "^(?=^.{6,14}$)(?=.*[0-9])(?=.*[a-zA-Z])(?=.*[^@$#])([a-zA-Z0-9^@$#]+)$"
            case .username:
                "^[A-Za-z0-9]{6,20}$"
            case .phone:
                "^[0-9]{11}$"
            case .realName:
                "^(?! )[\\p{Han} ·•]{2,50}(?<! )$"
            case .otp:
                "^[0-9]{6}$"
            case .id:
                "(?:[16][1-5]|2[1-3]|3[1-7]|4[1-6]|5[0-4])\\d{4}(?:19|20)\\d{2}(?:(?:0[469]|11)(?:0[1-9]|[12][0-9]|30)|(?:0[13578]|1[02])(?:0[1-9]|[12][0-9]|3[01])|02(?:0[1-9]|[12][0-9]))\\d{3}[\\dXx]"
            case .referrerCode:
                "^([A-Za-z0-9]{1,20})$"
            case .email:
                "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            case .receiverRemark:
                "^[a-zA-Z0-9\\s\\p{Han}.?()/&:!#,-]+"
            case .weChat:
                "^[a-zA-Z0-9.@_-]{4,20}$"
            case .address:
                "[A-Za-z0-9\\s\\p{Han}.()/&#,-]+"
            case .securityQuestionAnswer:
                "[A-Za-z0-9\\u4e00-\\u9fa5\\s\\p{Han}!#$(),./\\?_]+"
            case .serialNumber:
                "^[0-9]{16}$"
            case .securityCode:
                "^[0-9]{3}$"
            case .bankAccountNumber:
                "^[0-9]{16,19}$"
            case .bankName:
                "^[\\p{Han}a-zA-Z]{2,20}$"
            case .bankAddress:
                "^[\\p{Han}a-zA-Z]{2,50}$"
            case .cryptoWalletName:
                "^[a-zA-Z0-9/\\p{L}/u]{1,20}$"
            case .cryptoWalletAddressTRC:
                "^[T]{1}[a-zA-Z0-9]{33}+$"
            case .cryptoWalletAddressERC:
                "^[0x]{2}[a-zA-Z0-9]{40}+$"
            case .pureToken:
                "(?<=\\s).*"
            }
        }
    }

    public static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else {
            return false
        }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }

    public func valid(_ regex: Regex) -> Bool {
        self ~= regex.value
    }

    public func match(_ regex: String) -> [String] {
        let _string = self as NSString
        return (try? NSRegularExpression(pattern: regex))?
            .matches(
                in: self,
                range: NSRange(location: 0, length: _string.length)
            )
            .map {
                _string.substring(with: $0.range)
            } ?? []
    }

    public func match(_ regex: Regex) -> [String] {
        match(regex.value)
    }
}
