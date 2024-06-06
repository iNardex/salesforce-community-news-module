/** AUTOTEST: B2BNewsController_TEST **/
/**
 * Created by winardo on 3/13/2024.
 */

public without sharing class B2BNewsController {

	private static final String DEFAULT_SUFFIX = 'd';
	private static final String LOCALE_SUFFIX = 'n';

	private static final Integer DEFAULT_LIMIT = 10;

	@AuraEnabled(Cacheable=true)
	public static List<String> getTopicPicklistValues() {
		List<String> picklistValues = new List<String>();

		Schema.DescribeFieldResult fieldResult = News__c.Topic__c.getDescribe();
		List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

		for (Schema.PicklistEntry entry : picklistEntries) {
			picklistValues.add(entry.getLabel());
		}

		return picklistValues;
	}

	@AuraEnabled
	public static List<NewsWrapper> retrieveLastNews(Id accountId, String locale, Boolean isLoggedIn){
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveLastNews::accountId::' + accountId);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveLastNews::locale::' + locale);

		Id userId = UserInfo.getUserId();
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveLastNews::userId::' + userId);

		Contact contact = UserAccountDAO.getContactByUserId(userId);

		UserLoggedType userType = detectUserType(contact, isLoggedIn);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveLastNews::userType::' + userType);

		return retrieveNews(NewsType.DETAIL, userType, accountId, contact, locale, DEFAULT_LIMIT, null, null);
	}

	@AuraEnabled
	public static List<NewsWrapper> retrieveAllNews(Id accountId, String locale, Boolean isLoggedIn, Integer lim, Integer offset, String topic){
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveAllNews::accountId::' + accountId);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveAllNews::locale::' + locale);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveAllNews::isLoggedIn::' + isLoggedIn);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveAllNews::lim::' + lim);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveAllNews::offset::' + offset);

		Id userId = UserInfo.getUserId();
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveAllNews::userId::' + userId);

		Contact contact = UserAccountDAO.getContactByUserId(userId);

		UserLoggedType userType = detectUserType(contact, isLoggedIn);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveAllNews::userType::' + userType);

		return retrieveNews(NewsType.DETAIL, userType, accountId, contact, locale, lim, offset, topic);
	}

	@AuraEnabled
	public static List<NewsWrapper> retrieveCarouselNews(Id accountId, String locale, Boolean isLoggedIn){
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveCarouselNews::accountId::' + accountId);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveCarouselNews::locale::' + locale);

		Id userId = UserInfo.getUserId();
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveCarouselNews::userId::' + userId);

		Contact contact = UserAccountDAO.getContactByUserId(userId);

		UserLoggedType userType = detectUserType(contact, isLoggedIn);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveCarouselNews::userType::' + userType);

		return retrieveNews(NewsType.CAROUSEL, userType, accountId, contact, locale, DEFAULT_LIMIT, null, null);
	}

	@AuraEnabled
	public static NewsWrapper retrieveNews(Id newsId, String locale, Boolean isLoggedIn){
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveNews::locale::' + locale);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveNews::newsId::' + newsId);

		Id userId = UserInfo.getUserId();
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveCarouselNews::userId::' + userId);

		Contact contact = UserAccountDAO.getContactByUserId(userId);

		UserLoggedType userType = detectUserType(contact, isLoggedIn);

		News__c n = NewsDAO.retrieveNewsById(newsId);

		locale = sanitizeLocale(locale, userType);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveLastNews::locale (sanitized)::' + locale);

		List<NewsLocalized__c> localizeds = NewsDAO.retrieveLocalization(new Set<Id>{newsId}, locale);

		Map<String, NewsLocalized__c> localizedMap = new Map<String, NewsLocalized__c>();
		for(NewsLocalized__c nl : localizeds) {
			localizedMap.put(nl.News__c + (nl.IsDefault__c ? DEFAULT_SUFFIX : LOCALE_SUFFIX), nl);
		}

		NewsLocalized__c defLoc = localizedMap.get(n.Id + DEFAULT_SUFFIX);
		NewsLocalized__c loc = localizedMap.get(n.Id + LOCALE_SUFFIX);

		return createWrapper(n, defLoc, loc, NewsType.DETAIL, 0);
	}

	private static List<NewsWrapper> retrieveNews(NewsType newsType, UserLoggedType userType, Id accountId, Contact c, String locale, Integer lim, Integer off, String topic) {

		List<News__c> news = NewsDAO.retrieveNews(newsType, userType, c, lim, off, topic);

		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveLastNews::news::' + news.size());

		if(news.isEmpty()) {
			System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveLastNews::nothing to show');
			return new List<NewsWrapper>();
		}

		Integer countNews = NewsDAO.countNews(newsType, userType, topic);

		locale = sanitizeLocale(locale, userType);
		System.debug(LoggingLevel.DEBUG, 'B2BNewsController::retrieveLastNews::locale (sanitized)::' + locale);

		Set<Id> newsIds = new Set<Id>();
		for(News__c n : news) {
			newsIds.add(n.Id);
		}

		List<NewsLocalized__c> localizeds = NewsDAO.retrieveLocalization(newsIds, locale);
		Map<String, NewsLocalized__c> localizedMap = new Map<String, NewsLocalized__c>();
		for(NewsLocalized__c nl : localizeds) {
			localizedMap.put(nl.News__c + (nl.IsDefault__c ? DEFAULT_SUFFIX : LOCALE_SUFFIX), nl);
		}

		List<NewsWrapper> toReturn = new List<B2BNewsController.NewsWrapper>();
		for(News__c n : news) {
			NewsLocalized__c defLoc = localizedMap.get(n.Id + DEFAULT_SUFFIX);
			NewsLocalized__c loc = localizedMap.get(n.Id + LOCALE_SUFFIX);
			toReturn.add(createWrapper(n, defLoc, loc, newsType, countNews));
		}
		toReturn.sort();
		return toReturn;
	}

	private static NewsWrapper createWrapper(News__c news, NewsLocalized__c defLoc, NewsLocalized__c loc, NewsType newsType, Integer countNews) {
		Assert.isNotNull(defLoc);

		NewsWrapper wrapper = new NewsWrapper();
		wrapper.detailImageUrl = loc?.DetailImageUrl__c ?? defLoc.DetailImageUrl__c;
		wrapper.carouselImageUrl = loc?.CarouselImageUrl__c ?? defLoc.CarouselImageUrl__c;
		wrapper.title = loc?.Title__c ?? defLoc.Title__c;
		wrapper.body = loc?.Body__c ?? defLoc.Body__c;
		wrapper.youtubeUrl = loc?.YuotubeLink__c ?? defLoc.YuotubeLink__c;
		wrapper.videoPosition = (loc?.VideoPosition__c ?? defLoc.VideoPosition__c) ?? 'On bottom';
		wrapper.id = news.Id;
		wrapper.tag = news.Topic__c;
		wrapper.startDate = news.StartDate__c;
		wrapper.layout = news.Layout__c;
		wrapper.totalNews = countNews;
		wrapper.order = newsType == B2BNewsController.NewsType.DETAIL ? news.NewsSectionOrder__c?.intValue() : news.CarouselOrder__c?.intValue();
		return wrapper;
	}

	private static String sanitizeLocale(String locale, UserLoggedType userType) {
		if(String.isEmpty(locale)) {
			if(userType != UserLoggedType.GUEST) {
				return [SELECT LanguageLocaleKey FROM User WHERE Id = :UserInfo.getUserId()].LanguageLocaleKey;
			}
			else {
				return 'en_US';
			}
		}

		return locale;
	}

	private static UserLoggedType detectUserType(Contact contact, Boolean isLoggedIn) {
		if(!isLoggedIn) {
			return UserLoggedType.GUEST;
		}

		return UserLoggedType.LOGGED;
	}

	public enum UserLoggedType {
		GUEST,  LOGGED
	}

	public enum NewsType {
		CAROUSEL, DETAIL
	}

	public class NewsWrapper  implements Comparable {
		@AuraEnabled public String id {get; set;}
		@AuraEnabled public String layout {get; set;}
		@AuraEnabled public String detailImageUrl {get; set;}
		@AuraEnabled public String carouselImageUrl {get; set;}
		@AuraEnabled public String youtubeUrl {get; set;}
		@AuraEnabled public String videoPosition {get; set;}
		@AuraEnabled public String tag {get; set;}
		@AuraEnabled public Date startDate {get; set;}
		@AuraEnabled public String title {get; set;}
		@AuraEnabled public String body {get; set;}
		@AuraEnabled public Integer order {get; set;}
		@AuraEnabled public Integer totalNews {get; set;}

		public Integer compareTo(Object compareTo) {
			NewsWrapper compareToEmp = (NewsWrapper) compareTo;
			if(compareToEmp.order == null){
				return -1;
			}
			if(this.order == null){
				return 1;
			}
			if(compareToEmp.order == this.order){
				return 0;
			}
			return compareToEmp.order > this.order ? 0 : 1;
		}
	}

}