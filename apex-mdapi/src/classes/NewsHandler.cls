/** AUTOTEST: News_TEST, B2BNewsController_TEST **/
/**
 * Created by winardo on 3/8/2024.
 */

public inherited sharing class NewsHandler {

	public static final String DEFAULT_LOCALE = 'en_US';
	private static final String CONTACT_TIPOLOGY_ALL = 'All';
	private static final String CONTACT_TIPOLOGY_AGENT = 'Agent';
	private static final String CONTACT_TIPOLOGY_CATUSER = 'Cat User';
	private static final String CONTACT_TIPOLOGY_CATSUPERVISOR = 'Cat Supervisor';
	private static final String CONTACT_TIPOLOGY_CLIENTAGENT = 'Client Agent';
	private static final String CONTACT_TIPOLOGY_CLIENT = 'Client';
	private static final String CONTACT_TIPOLOGY_SUPERGUEST = 'Super Guest';

	public static void initNews(List<News__c> news) {
		System.debug(LoggingLevel.DEBUG, 'NewsHandler::initNews::news::' + news.size());

		List<NewsLocalized__c> defaultLocal = new List<NewsLocalized__c>();
		for(News__c n : news){
			NewsLocalized__c nl = new NewsLocalized__c();
			nl.Name = n.Name + ' - ' + DEFAULT_LOCALE;
			nl.Locale__c = DEFAULT_LOCALE;
			nl.IsDefault__c = true;
			nl.News__c = n.Id;
			defaultLocal.add(nl);
		}

		insert defaultLocal;
	}

	public static void initNewsLocalized(List<NewsLocalized__c> newsLocalized) {
		System.debug(LoggingLevel.DEBUG, 'NewsHandler::initNews::newsLocalized::' + newsLocalized.size());

		Set<Id> newsIds = new Set<Id>();
		for(NewsLocalized__c nl : newsLocalized){
			newsIds.add(nl.News__c);
		}

		Map<Id, Set<String>> newsLocaleMap = getNewsLocaleMap(newsIds);

		Map<Id, News__c> newsMap = new Map<Id, News__c>([
			SELECT Id, Name
			FROM News__c
			WHERE Id IN :newsIds
		]);
		System.debug(LoggingLevel.DEBUG, 'NewsHandler::initNews::newsMap::' + newsMap.size());

		for(NewsLocalized__c nl : newsLocalized){
			Set<String> allLocaleInNews = newsLocaleMap.get(nl.News__c);
			if(allLocaleInNews != null && allLocaleInNews.contains(nl.Locale__c)){
				nl.addError('Locale__c', 'This language already exist');
			}
			nl.Name = newsMap.get(nl.News__c).Name + ' - ' + nl.Locale__c;
		}
	}

	private static Map<Id, Set<String>> getNewsLocaleMap(Set<Id> newsIds) {
		List<NewsLocalized__c> allLocalized = NewsDAO.getNewsLocalizedByNewsIds(newsIds, false);
		Map<Id, Set<String>> newsLocaleMap = new Map<Id, Set<String>>();
		for(NewsLocalized__c nl : allLocalized) {
			if(!newsLocaleMap.containsKey(nl.News__c)) {
				newsLocaleMap.put(nl.News__c, new Set<String>());
			}

			newsLocaleMap.get(nl.News__c).add(nl.Locale__c);
		}
		return newsLocaleMap;
	}

	public static void blockDefaultDelete(List<NewsLocalized__c> newsLocalizeds) {
		for(NewsLocalized__c nl : newsLocalizeds){
			if(nl.IsDefault__c){
				nl.addError('You can\'t delete default localization');
			}
		}
	}

	public static void validatePubblish(List<News__c> news, Map<Id, News__c> oldNews) {
		System.debug(LoggingLevel.DEBUG, 'NewsHandler::validatePubblish::news::' + news.size());
		List<Id> newsIds = new List<Id>();
		List<News__c> toProcess = new List<News__c>();
		for(News__c n : news){
			News__c oldN = oldNews.get(n.Id);
			if(n.Status__c != oldN.Status__c && n.Status__c == 'Published'){
				newsIds.add(n.Id);
				toProcess.add(n);
			}
		}

		System.debug('NewsHandler::validatePubblish::toProcess::' + toProcess.size());
		if(toProcess.isEmpty()){
			System.debug('NewsHandler::validatePubblish::not to do');
			return;
		}

		Map<Id, NewsLocalized__c> newsLocalizedDefault = getDefaultLocalization(newsIds);
		for(News__c n : toProcess){
			NewsLocalized__c nl = newsLocalizedDefault.get(n.Id);

			if(String.isEmpty(nl.Title__c)){
				n.addError('Status__c', 'Default localization must have a Title');
			}

			if(String.isEmpty(nl.Body__c)){
				n.addError('Status__c', 'Default localization must have a Body');
			}

			if(n.VisibleCarousel__c && String.isEmpty(nl.CarouselImageUrl__c)){
				n.addError('VisibleCarousel__c', 'Default localization must have a Carousel Image');
			}

			if(n.VisibleNewsSection__c && String.isEmpty(nl.DetailImageUrl__c)){
				n.addError('VisibleNewsSection__c', 'Default localization must have a Detail Image');
			}
		}

	}

	private static Map<Id, NewsLocalized__c> getDefaultLocalization(List<Id> newsIds) {
		Map<Id, NewsLocalized__c> newsLocalizedDefault = new Map<Id, NewsLocalized__c>();
		List<NewsLocalized__c> defaultNewsLocalized = NewsDAO.getNewsLocalizedByNewsIds(new Set<Id>(newsIds), true);
		for(NewsLocalized__c nl : defaultNewsLocalized) {
			newsLocalizedDefault.put(nl.News__c, nl);
		}
		return newsLocalizedDefault;
	}

}