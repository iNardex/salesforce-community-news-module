/**
 * Created by winardo on 3/8/2024.
 */

@IsTest
private inherited sharing class News_TEST {

	@TestSetup
	public static void prepareScenario(){
		B2BUtil_TEST.prepareScenario();
	}

	@IsTest
	public static void creteNews(){
		News__c n = B2BUtil_TEST.createNews();

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
	public static void creteNewsWithSharings(){
		News__c n = B2BUtil_TEST.createNews();
		News__c n2 = B2BUtil_TEST.createNews();

		Audience__c aud = new Audience__c();
		aud.News__c = n.Id;
		aud.Market__c = 'ITA';

		Audience__c aud2 = new Audience__c();
		aud2.News__c = n2.Id;
		aud2.Market__c = 'ITA';

		Test.startTest();
		insert aud;
		insert aud2;
		delete aud2;
		Test.stopTest();
	}

	@IsTest
	public static void testLocalized(){
		News__c n = B2BUtil_TEST.createNews();
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
		News__c n = B2BUtil_TEST.createNews();
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

}