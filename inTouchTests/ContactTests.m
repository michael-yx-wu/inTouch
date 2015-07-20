#import <XCTest/XCTest.h>

#import "Contact.h"
#import "FetchRequestStrings.h"

@interface ContactTests : XCTestCase {
    NSManagedObjectContext *moc;
    NSManagedObjectModel *mom;
    NSPersistentStoreCoordinator *psc;
}

@end

@implementation ContactTests

- (void)setUp {
    [super setUp];
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    XCTAssertTrue([psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL] ? YES : NO, @"Should be able to add in-memory store");
    moc = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:psc];
}

- (void)tearDown {
    [super tearDown];
    moc = nil;
    psc = nil;
    mom = nil;
}

- (void)save {
    XCTAssertTrue([moc save:NULL], @"Save error");
}

#pragma mark - Tests

- (void)testContactCreate {
    Contact *contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:moc];
    [contact setNameFirst:@"firstname"];
    [contact setNameLast:@"lastname"];
    [contact setCategory:[NSNumber numberWithInt:1]];
    [contact setMetadata:nil];
    [self save];
    
    // Verify number of contacts increased by 1
    NSFetchRequest *request = [mom fetchRequestTemplateForName:allContacts];
    NSArray *results = [moc executeFetchRequest:request error:NULL];
    XCTAssertNotNil(results, @"Fetch failed");
    XCTAssertTrue([results count] == 1, @"Size of fetch result should be 1");
    
    // Verify details have been correctly saved
    Contact *fetchedContact = [results objectAtIndex:0];
    XCTAssertTrue([[fetchedContact nameFirst] isEqualToString:@"firstname"], @"First name incorrect");
    XCTAssertTrue([[fetchedContact nameLast] isEqualToString:@"lastname"], @"Last name incorrect");
    XCTAssertTrue([[fetchedContact category] intValue] == 1, @"Category incorrect");
    XCTAssertNil([fetchedContact metadata], @"Metadata should be nil");
}

@end
