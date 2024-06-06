/** AUTOTEST: News_TEST,B2BNewsController_TEST **/
/**
 * Created by winardo on 3/8/2024.
 */

public inherited sharing class NewsDAO {

	public static List<NewsLocalized__c> getNewsLocalizedByNewsIds(Set<Id> newsIds, Boolean onlyDefault){
		System.debug(LoggingLevel.DEBUG, 'NewsDAO::getNewsLocalizedByNewsIds::newsIds::' + newsIds.size());
		System.debug(LoggingLevel.DEBUG, 'NewsDAO::getNewsLocalizedByNewsIds::onlyDefault::' + onlyDefault);

		String soql = 'SELECT Id, Locale__c, Body__c, Title__c, News__c, CarouselImageUrl__c, DetailImageUrl__c ' +
			'FROM NewsLocalized__c ' +
			'WHERE News__c IN :newsIds ';
		if(onlyDefault){
			soql += ' AND IsDefault__c = TRUE';
		}

		System.debug(LoggingLevel.FINEST, 'NewsDAO::getNewsLocalizedByNewsIds::soql::' + soql);
		return Database.query(soql);
	}

	public static NewsLocalized__c getNewsLocalizedById(Id newsLocalizedId){
		return [
			SELECT Id, DetailImageUrl__c, CarouselImageUrl__c,
				CarouselContentDocumentId__c, DetailContentDocumentId__c
			FROM NewsLocalized__c
			WHERE Id = :newsLocalizedId LIMIT 1
		];
	}

	public static News__c retrieveNewsById(Id newsId){
		return [
			SELECT Id, StartDate__c, Topic__c, NewsSectionOrder__c, CarouselOrder__c, Layout__c FROM News__c WHERE Id = :newsId LIMIT 1
		];
	}

	public static List<News__c> retrieveNews(B2BNewsController.NewsType newsType, B2BNewsController.UserLoggedType userType, Contact c, Integer lim, Integer off, String topic){
		String visibilityStatment = getVisibilityStatment(userType);

		Date today = Date.today();

		String soql = 'SELECT Id, NewsSectionOrder__c, CarouselOrder__c, Layout__c, StartDate__c, Topic__c, EndDate__c ' +
			' FROM News__c ' +
			' WHERE (Status__c = \'Published\' AND ' + visibilityStatment +
			' AND ((StartDate__c <= :today AND (EndDate__c >= :today OR EndDate__c = null))) ' +
			' AND ';

		if (newsType == B2BNewsController.NewsType.DETAIL) {
			soql += ' VisibleNewsSection__c = TRUE';

			if (topic != null && !topic.equalsIgnoreCase('All') && !String.isBlank(topic)) {
				soql += ' AND Topic__c = :topic';
			}

			soql += ') ORDER BY NewsSectionOrder__c ASC';
		} else {
			soql += ' VisibleCarousel__c = TRUE )';
			soql += ' ORDER BY CarouselOrder__c ASC ';
		}

		if(lim != null){
			soql += ' LIMIT :lim ';
			if(off != null){
				soql += ' OFFSET :off ';
			}
		}

		System.debug('::NewsDAO::retrieveNews::topic' + topic);
		System.debug('::NewsDAO::retrieveNews::' + soql);

		return Database.query(soql);
	}

	private static String getVisibilityStatment(B2BNewsController.UserLoggedType userType) {
		String visibilityStatment = ' (Visibility__c = \'Public\' ';
		if(userType != B2BNewsController.UserLoggedType.GUEST) {
			visibilityStatment += 'OR (Visibility__c = \'Private\')';
		}
		visibilityStatment += ')';
		return visibilityStatment;
	}

	public static Integer countNews(B2BNewsController.NewsType newsType, B2BNewsController.UserLoggedType userType, String topic) {
		String visibilityStatment = getVisibilityStatment(userType);

		Date today = Date.today();
		String soql = 'SELECT COUNT(ID) ' +
			' FROM News__c ' +
			' WHERE (Status__c = \'Published\' AND ' + visibilityStatment +
			' AND ((StartDate__c <= :today AND (EndDate__c >= :today OR EndDate__c = null))) ' +
			' AND ';

		if(newsType == B2BNewsController.NewsType.DETAIL){
			soql += ' VisibleNewsSection__c = TRUE ';

			if (topic != null && !topic.equalsIgnoreCase('All') && !String.isBlank(topic)) {
				soql += ' AND Topic__c = :topic';
			}

			soql += ')';
		} else {
			soql += ' VisibleCarousel__c = TRUE )';
		}

		List<AggregateResult> ar = Database.query(soql);
		return ar.isEmpty() ? 0 : Integer.valueOf(ar.get(0).get('expr0'));
	}

	public static List<NewsLocalized__c> retrieveLocalization(Set<Id> newsIds, String locale){
		return [
			SELECT Id, DetailImageUrl__c, CarouselImageUrl__c, Title__c, Body__c, News__c, IsDefault__c, Locale__c, YuotubeLink__c, VideoPosition__c
			FROM NewsLocalized__c
			WHERE News__c IN :newsIds
				AND (IsDefault__c = TRUE OR Locale__c = :locale)
		];
	}

}