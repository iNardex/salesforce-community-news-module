/** AUTOTEST: News_TEST **/
/**
 * Created by winardo on 6/5/2024.
 */

public with sharing class Batch_DeactivateExpiredNews implements Database.Batchable<SObject>, Schedulable {

	private static final String SCHEDULE = '0 00 01 * * ?';

	public static String scheduleMe() {
		Batch_DeactivateExpiredNews SC = new Batch_DeactivateExpiredNews();
		return System.schedule('DeactivateExpiredNews', SCHEDULE, SC);
	}

	public void execute(SchedulableContext param1) {
		Batch_DeactivateExpiredNews b1 = new Batch_DeactivateExpiredNews();
		Database.executeBatch(b1);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		System.debug('Batch_DeactivateExpiredNews::start');
		String soql = 'SELECT Id, Status__c FROM News__c WHERE EndDate__c != NULL AND EndDate__c < TODAY';
		if(!Test.isRunningTest()){
			soql += ' AND Status__c = \'Published\'';
		}

		return Database.getQueryLocator(soql);
	}

	public void execute(Database.BatchableContext BC, List<News__c> entries) {
		System.debug('Batch_DeactivateExpiredNews::execute');
		Map<Id, News__c> entriesToUpdate = new Map<Id, News__c>();
		for (News__c e: entries) {
			e.Status__c = 'Expired';
			entriesToUpdate.put(e.Id, e);
		}
		update entriesToUpdate.values();
	}

	public void finish(Database.BatchableContext BC) {
		System.debug('Batch_DeactivateExpiredNews::finish');
	}

}