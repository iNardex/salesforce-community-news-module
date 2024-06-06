/** AUTOTEST: News_TEST **/
/**
 * Created by winardo on 3/11/2024.
 */

public with sharing class B2BNewsLocalizedController {

	@AuraEnabled
	public static NewsLocalized__c retrieveNewsLocalized(Id newsLocalizedId){
		return NewsDAO.getNewsLocalizedById(newsLocalizedId);
	}

	@AuraEnabled
	public static String createAttachment(Id newsLocalizedId, String attachmentId, String mode){
		final String attachmentUrl = getDocPublicLink(attachmentId);
		System.debug('B2BNewsLocalizedController::createAttachment::attachmentUrl::' + attachmentUrl);

		ModeEnum m = ModeEnum.valueOf(mode);

		NewsLocalized__c nl = new NewsLocalized__c(Id = newsLocalizedId);
		if(m == ModeEnum.Carousel){
			nl.CarouselImageUrl__c = attachmentUrl;
			nl.CarouselContentDocumentId__c = attachmentId;
		} else {
			nl.DetailImageUrl__c = attachmentUrl;
			nl.DetailContentDocumentId__c = attachmentId;
		}
		update nl;

		return attachmentUrl;
	}

	@AuraEnabled
	public static void deleteAttachment(Id newsLocalizedId, String mode){
		NewsLocalized__c nl = NewsDAO.getNewsLocalizedById(newsLocalizedId);

		ContentDocument cd = null;
		ModeEnum m = ModeEnum.valueOf(mode);
		if(m == ModeEnum.Carousel){
			nl.CarouselImageUrl__c = null;
			cd = new ContentDocument(Id = nl.CarouselContentDocumentId__c);
		} else {
			nl.DetailImageUrl__c = null;
			cd = new ContentDocument(Id = nl.DetailContentDocumentId__c);
		}

		delete cd;

		update nl;
	}

	private static String getDocPublicLink(Id documentId) {
		ContentVersion cv = [SELECT Id, VersionData, ContentDocument.Title FROM ContentVersion WHERE ContentDocumentId = :documentId LIMIT 1];

		ContentDistribution cd = new ContentDistribution();
		cd.Name = cv.ContentDocument.Title;
		cd.ContentVersionId = cv.Id;
		cd.PreferencesAllowViewInBrowser = true;
		cd.PreferencesLinkLatestVersion = true;
		cd.PreferencesNotifyOnVisit = false;
		cd.PreferencesPasswordRequired = false;
		cd.PreferencesAllowOriginalDownload = true;
		insert cd;

		//Download URL can be pass as parameter to holding frames
		return [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE Id = :cd.Id].ContentDownloadUrl;
	}

	public enum ModeEnum {
		Carousel, Detail
	}

}