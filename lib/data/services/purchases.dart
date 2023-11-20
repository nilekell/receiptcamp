// ignore_for_file: unused_field, unused_element

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesService {
  PurchasesService._getInstance();
  static final PurchasesService _instance = PurchasesService._getInstance();
  static PurchasesService get instance => _instance;

  Offering? _proOffering;
  Offering? get proOffering => _proOffering;

  Package? _subscriptionPackage;
  Package? _lifetimePackage;

  CustomerInfo? _customerInfo;

  bool _userIsPro = false;
  // bool get userIsPro => false, when testing to always show PayWall and payment flow
  bool get userIsPro => false;

  final String _revenueCatiOSApiKey = 'appl_FKvwuFnkweReYdMSvRjUCQqGZFs';
  final String _revenueCatAndroidApiKey = 'goog_iKvfzRIURBzwgXzXBRNnPkqPODo';

  final String _receiptCampProEntitlementId = 'ReceiptCamp Pro';

  Future<void> initPlatformState() async {
    try {
      // print('PurchasesService init');
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration? configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_revenueCatAndroidApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_revenueCatiOSApiKey);
      }

      if (configuration == null) {
        throw Exception(
            'PurchasesService: PurchasesConfiguration failed to initialise.');
      }

      await Purchases.configure(configuration);

      await _fetchAvailableOfferings();
      await checkCustomerPurchaseStatus();

      // _outputPurchaseServiceInfo();
      // _outputLifetimePackageDetails();
      // _outputCustomerInfo();

      print('_userIsPro = $_userIsPro');

    } on Exception catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<void> _fetchAvailableOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        _proOffering = offerings.current;
        _lifetimePackage = _proOffering!.lifetime;
        // _subscriptionPackage = _proOffering!.monthly;
      }
    } on PlatformException catch (e) {
      print(e.toString());
      print('Failed to fetch products');
    }
  }

   Future<void> checkCustomerPurchaseStatus() async {
    try {
      CustomerInfo latestCustomerInfo = await Purchases.getCustomerInfo();
      _customerInfo = latestCustomerInfo;
      // customerInfo.entitlements.all will be null when the user
      // has not purchased a product that’s attached to an entitlement yet, the EntitlementInfo object
      if (latestCustomerInfo.allPurchasedProductIdentifiers.isNotEmpty) {
        _userIsPro = true;
      } else {
        _userIsPro = false;
      }
    } on PlatformException catch (e) {
      print(e.toString());
      _userIsPro = false;
    }
  }

  // works on android only
  Future<bool> canMakePayments() async {
    try {
      if ((await Purchases.canMakePayments())) {
        return true;
      } else {
        return false;
      }
    } on Exception catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<bool> makeProLifetimePurchase() async {
    try {
      CustomerInfo purchaserInfo =
          await Purchases.purchasePackage(_lifetimePackage!);
      EntitlementInfo? entitlement = purchaserInfo
          .entitlements.all[_receiptCampProEntitlementId];
      if (entitlement!.isActive) {
        _userIsPro = true;
        return true;
      } else {
        _userIsPro = false;
        return false;
      }
    } on PlatformException catch (e) {
      print('Purchase failed: $e');
      return false;
    }
  }

  // Future<bool> makeProSubscriptionPurchase() async {
  //   try {
  //     CustomerInfo purchaserInfo =
  //         await Purchases.purchasePackage(_subscriptionPackage!);
  //     EntitlementInfo? entitlement = purchaserInfo
  //         .entitlements.all[_receiptCampProEntitlementId];
  //     if (entitlement!.isActive) {
  //       _userIsPro = true;
  //       return true;
  //     } else {
  //       _userIsPro = false;
  //       return false;
  //     }
  //   } on PlatformException catch (e) {
  //     print('Purchase failed: $e');
  //     return false;
  //   }
  // }

  Future<void> restorePurchases() async {
    try {
      CustomerInfo restoredCustomerInfo = await Purchases.restorePurchases();
      _customerInfo = restoredCustomerInfo;
      print('restored activeSubscriptions: ${restoredCustomerInfo.activeSubscriptions}');
      print('restored entitlements: ${restoredCustomerInfo.entitlements}');
      print('restored purchased products: ${restoredCustomerInfo.allPurchasedProductIdentifiers}');
      // checking restored customerInfo to see if entitlement is now active
      // user was never a pro member when there are no active subscriptions and no purchased products
      if (restoredCustomerInfo.activeSubscriptions.isEmpty && restoredCustomerInfo.allPurchasedProductIdentifiers.isEmpty) {
        _userIsPro = false;
        return;
      }

      // user is a pro member when their entitlement is active, they have an active subscription or a purchased product
      if (restoredCustomerInfo.entitlements.all[_receiptCampProEntitlementId]!.isActive || restoredCustomerInfo.activeSubscriptions.isNotEmpty || restoredCustomerInfo.allPurchasedProductIdentifiers.isNotEmpty) {
        _userIsPro = true;
      } else {
        _userIsPro = false;
      }

    } on PlatformException catch (e) {
      print(e.toString());
    }
  }

   void _outputCustomerInfo() {
    if (_customerInfo != null) {
      print('\n');
      print('''/////////////////////////////''');
      print('originalAppUserId: ${_customerInfo!.originalAppUserId}');
      print('activeSubscriptions: ${_customerInfo!.activeSubscriptions}');
      print('allPurchasedProductIdentifiers: ${_customerInfo!.allPurchasedProductIdentifiers}');
      print('''/////////////////////////////''');
      print('\n');
    } else {
      print('customer info is null');
    }
  }

  void _outputPurchaseServiceInfo() {
    print('\n');
      print('''/////////////////////////////''');
    print('Offering: ${proOffering!.identifier}, Description: ${proOffering!.serverDescription}');
    print('Available Packages:');
    for (var package in proOffering!.availablePackages) {
      print('Package Identifier: ${package.identifier}, Package Type: ${package.packageType}');
      StoreProduct product = package.storeProduct;
      print('Store Product Identifier: ${product.identifier}, Title: ${product.title}, Description: ${product.description}, Price: ${product.price}, Currency: ${product.currencyCode}, Product Category: ${product.productCategory}');
      // print('Introductory Price: ${product.introductoryPrice}');
      // print('Discounts: ${product.discounts}');
    }
    print('''/////////////////////////////''');
      print('\n');
  }

  // void _outputSubscriptionPackageDetails() {
  //   print('Subscription Package details');
  //   print('identifier: ${_subscriptionPackage!.identifier}');
  //   print('offering identifier: ${_subscriptionPackage!.offeringIdentifier}');
  //   print('package type: ${_subscriptionPackage!.packageType}');
  // }

  void _outputLifetimePackageDetails() {
    print('Lifetime Package details');
    print('identifier: ${_lifetimePackage!.identifier}');
    print('offering identifier: ${_lifetimePackage!.offeringIdentifier}');
    print('package type: ${_lifetimePackage!.packageType}');
  }
}
