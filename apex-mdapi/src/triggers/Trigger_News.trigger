/** AUTOTEST: News_TEST **/
/**
 * Created by winardo on 3/8/2024.
 */

trigger Trigger_News on News__c (before insert, before update, after insert, after update, after delete) {
	if(Trigger.isBefore && Trigger.isInsert) {
		System.debug('Trigger_News::isBefore::isInsert');
	} else if(Trigger.isBefore && Trigger.isUpdate){
		System.debug('Trigger_News::isBefore::isUpdate');
		NewsHandler.validatePubblish(Trigger.new, Trigger.oldMap);
	} else if(Trigger.isAfter && Trigger.isInsert){
		System.debug('Trigger_News::isAfter::isInsert');
		NewsHandler.initNews(Trigger.new);
	} else if(Trigger.isAfter && Trigger.isUpdate){
		System.debug('Trigger_News::isAfter::isUpdate');
	}
}