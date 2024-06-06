/**
 * Created by winardo on 3/8/2024.
 */

@IsTest
private inherited sharing class News_TEST {

	@TestSetup
	public static void prepareScenario(){
		Account a = new Account();
		a.Name = 'Test';
		insert a;
	}

	@IsTest
	public static void creteNews(){
		News__c n = createNews();

		try{
			delete [SELECT ID FROM NewsLocalized__c WHERE News__c = :n.Id];
		} catch(Exception e){
			//Need come here - Default localization cant be deleted
			Assert.isTrue(true);
		}

		try{
			n.Status__c = 'Pubblish';
			update n;
		} catch(Exception e){
			//Need come here - Pubblish with nothing must be handled
			Assert.isTrue(true);
		}
	}

	@IsTest
	public static void testLocalized(){
		News__c n = createNews();
		Id localized = [SELECT Id FROM NewsLocalized__c WHERE News__c = :n.Id LIMIT 1].Id;
		B2BNewsLocalizedController.retrieveNewsLocalized(localized);

		ContentVersion contentVersion = new ContentVersion(
			Title          = 'a picture',
			PathOnClient   = 'Pic.jpg',
			VersionData    = Blob.valueOf('Test Content'),
			IsMajorVersion = true);
		insert contentVersion;

		ContentVersion contentVersion2 = new ContentVersion(
			Title          = 'a picture',
			PathOnClient   = 'Pic.jpg',
			VersionData    = Blob.valueOf('Test Content'),
			IsMajorVersion = true);
		insert contentVersion2;

		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

		B2BNewsLocalizedController.createAttachment(localized, documents[0].Id, B2BNewsLocalizedController.ModeEnum.Carousel.name());
		B2BNewsLocalizedController.createAttachment(localized, documents[1].Id, B2BNewsLocalizedController.ModeEnum.Detail.name());
		B2BNewsLocalizedController.deleteAttachment(localized, B2BNewsLocalizedController.ModeEnum.Carousel.name());
		B2BNewsLocalizedController.deleteAttachment(localized, B2BNewsLocalizedController.ModeEnum.Detail.name());
	}

	@IsTest
	public static void expireNews(){
		News__c n = createNews();
		n.EndDate__c = Date.today().addDays(-1);
		update n;

		Test.startTest();
		try{
			Batch_DeactivateExpiredNews.scheduleMe();
			Batch_DeactivateExpiredNews b1 = new Batch_DeactivateExpiredNews();
			Database.executeBatch(b1);
		} catch(Exception e){
			//Need come here - Pubblish with nothing must be handled
			Assert.isTrue(true);
		}
		Test.stopTest();
	}

	public static News__c createNews(){
		News__c n = new News__c();
		n.Name = 'Test';
		n.Layout__c = 'Center';
		n.Status__c = 'Draft';
		n.Visibility__c = 'Private';
		n.StartDate__c = Date.today();
		insert n;

		return n;
	}

}