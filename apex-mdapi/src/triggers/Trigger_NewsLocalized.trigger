/** AUTOTEST: News_TEST **/
/**
 * Created by winardo on 3/8/2024.
 */

trigger Trigger_NewsLocalized on NewsLocalized__c (before insert, before update, before delete, after insert, after update, after delete) {
	if(Trigger.isBefore && Trigger.isInsert) {
		System.debug('Trigger_NewsLocalized::isBefore::isInsert');
		NewsHandler.initNewsLocalized(Trigger.new);
	}
	else if(Trigger.isBefore && Trigger.isUpdate) {
		System.debug('Trigger_NewsLocalized::isBefore::isUpdate');
	}
	else if(Trigger.isBefore && Trigger.isDelete) {
		System.debug('Trigger_NewsLocalized::isBefore::isDelete');
		NewsHandler.blockDefaultDelete(Trigger.old);
	}
	else if(Trigger.isAfter && Trigger.isInsert) {
		System.debug('Trigger_NewsLocalized::isAfter::isInsert');

	}
	else if(Trigger.isAfter && Trigger.isUpdate) {
		System.debug('Trigger_NewsLocalized::isAfter::isUpdate');
	}
}