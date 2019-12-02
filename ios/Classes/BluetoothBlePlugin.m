#import "BluetoothBlePlugin.h"
#import <bluetooth_ble/bluetooth_ble-Swift.h>

@implementation BluetoothBlePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBluetoothBlePlugin registerWithRegistrar:registrar];
}
@end
