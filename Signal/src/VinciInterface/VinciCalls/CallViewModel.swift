//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public class CallViewModel: NSObject {
    @objc public let isMissed: Bool
    @objc public let callRecord: TSCall
    
    @objc
    public init(call: TSCall, transaction: YapDatabaseReadTransaction) {
        self.isMissed = false
        self.callRecord = call
    }
    
    @objc
    override public func isEqual(_ object: Any?) -> Bool {
        guard let otherCall = object as? CallViewModel else {
            return super.isEqual(object)
        }
        
        return callRecord.isEqual(otherCall.callRecord)
    }
}
