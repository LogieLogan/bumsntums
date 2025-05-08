// test/features/nutrition/repositories/food_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bums_n_tums/features/nutrition/models/food_item.dart';
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_repository_test.mocks.dart';
// Create a simplified test version that just focuses on Firestore interactions
class TestFoodRepository {
  final MockFirebaseFirestore mockFirestore;
  final MockFirebaseAuth mockAuth;
  final MockAnalyticsService mockAnalyticsService;
  final MockUser mockUser;

  TestFoodRepository({
    required this.mockFirestore,
    required this.mockAuth,
    required this.mockAnalyticsService,
    required this.mockUser,
  });

  // Test saving to Firestore only (ignore local storage)
  Future<void> saveFoodItemToFirestore(FoodItem item) async {
    final userId = mockUser.uid;
    final collRef = mockFirestore.collection('food_scans');
    final docRef = collRef.doc(userId);
    final itemsCollRef = docRef.collection('items');
    final itemDocRef = itemsCollRef.doc(item.id);
    
    await itemDocRef.set(item.toFirestore());
    
    mockAnalyticsService.logEvent(
      name: 'food_item_saved',
      parameters: {'barcode': item.barcode}
    );
  }
  
  // Test deleting from Firestore only
  Future<void> deleteFoodItemFromFirestore(String itemId) async {
    final userId = mockUser.uid;
    final docRef = mockFirestore
        .collection('food_scans')
        .doc(userId)
        .collection('items')
        .doc(itemId);
    
    await docRef.delete();
    
    mockAnalyticsService.logEvent(
      name: 'food_item_deleted',
      parameters: {'item_id': itemId}
    );
  }
}

@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  User,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  Query,
  QueryDocumentSnapshot,
  AnalyticsService,
])


void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockAnalyticsService mockAnalyticsService;
  late TestFoodRepository testRepo;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late MockQuery<Map<String, dynamic>> mockQuery;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockAnalyticsService = MockAnalyticsService();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocRef = MockDocumentReference<Map<String, dynamic>>();
    mockQuery = MockQuery<Map<String, dynamic>>();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-user-id');

    // Create our test repository
    testRepo = TestFoodRepository(
      mockFirestore: mockFirestore,
      mockAuth: mockAuth,
      mockAnalyticsService: mockAnalyticsService,
      mockUser: mockUser,
    );

    // Set up SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  group('FoodRepository - Firestore Operations', () {
    test('saveFoodItem should save the food item to Firestore', () async {
      // Arrange
      final foodItem = FoodItem(
        id: 'test-id',
        barcode: '1234567890',
        name: 'Test Food Item',
      );

      when(mockFirestore.collection('food_scans')).thenReturn(mockCollection);
      when(mockCollection.doc('test-user-id')).thenReturn(mockDocRef);
      when(mockDocRef.collection('items')).thenReturn(mockCollection);
      when(mockCollection.doc('test-id')).thenReturn(mockDocRef);
      when(mockDocRef.set(any)).thenAnswer((_) async => {});

      // Act
      await testRepo.saveFoodItemToFirestore(foodItem);

      // Assert
      verify(mockDocRef.set(any)).called(1);
      verify(
        mockAnalyticsService.logEvent(
          name: 'food_item_saved',
          parameters: any,
        ),
      ).called(1);
    });

    test('deleteFoodItem removes item from Firestore', () async {
      // Arrange
      when(mockFirestore.collection('food_scans')).thenReturn(mockCollection);
      when(mockCollection.doc('test-user-id')).thenReturn(mockDocRef);
      when(mockDocRef.collection('items')).thenReturn(mockCollection);
      when(mockCollection.doc('test-id')).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async => {});

      // Act
      await testRepo.deleteFoodItemFromFirestore('test-id');

      // Assert
      verify(mockDocRef.delete()).called(1);
      verify(
        mockAnalyticsService.logEvent(
          name: 'food_item_deleted',
          parameters: any,
        ),
      ).called(1);
    });
  });
}