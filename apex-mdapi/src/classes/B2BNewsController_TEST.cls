/**
 * Created by winardo on 3/19/2024.
 */

@IsTest
private class B2BNewsController_TEST {

	@TestSetup
	public static void prepareScenario(){
		Account a = new Account();
		a.Name = 'Test';
		insert a;

	}

	@IsTest
	public static void test_retrieveLastNews(){
		News__c n = createNews();

		NewsLocalized__c nl = [SELECT Id FROM NewsLocalized__c WHERE News__c = :n.Id LIMIT 1];
		nl.Title__c = 'TEST';
		nl.Body__c = 'TEST';
		nl.CarouselImageUrl__c = 'TEST';
		nl.DetailImageUrl__c = 'TEST';

		update nl;

		n.Visibility__c = 'Public';
		n.Status__c = 'Published';
		n.VisibleCarousel__c = true;
		n.VisibleNewsSection__c = true;

		update n;

		Account a = [SELECT Id FROM Account LIMIT 1];

		B2BNewsController.retrieveLastNews(a.Id, 'en_US', true);
		B2BNewsController.retrieveCarouselNews(a.Id, 'en_US', true);
		B2BNewsController.retrieveAllNews(a.Id, 'en_US', true, 0, 3, null);
		B2BNewsController.retrieveAllNews(a.Id, '', true, 0, 3,'News');
		B2BNewsController.retrieveNews(n.Id, 'en_US', true);
		B2BNewsController.getTopicPicklistValues();

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