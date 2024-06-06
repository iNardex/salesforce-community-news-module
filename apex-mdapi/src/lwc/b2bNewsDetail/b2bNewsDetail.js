/**
 * Created by winardo on 3/19/2024.
 */

import { LightningElement, api, track } from 'lwc';

import siteId from "@salesforce/site/Id";
import { getSessionContext, getAppContext } from 'commerce/contextApi';

import retrieveNews from '@salesforce/apex/B2BNewsController.retrieveNews';

export default class B2BNewsDetail extends LightningElement {

	@api recordId;
	langOptions = [
        {
            value: "en-US",
            valueBe: "en_US"
        },
        {
            value: "pt-BR",
            valueBe: "pt_BR",
        },
        {
            value: "es",
            valueBe: "es"
        }
    ];

	@track isLoading = true;
	cookies;
	@track videoBottom;
	@track videoTop;
	locale;
	effectiveAccountId;
	isLoggedIn;
	news;

	connectedCallback(){
		this.cookies = document.cookie.split(';').map(c=> c.trim()).map(c=> {
            return {
                name: c.split('=')[0],
                value: c.split('=')[1]
            };
        });

        let cookieLang = this.cookies.find(c => c.name === ('PreferredLanguage' + siteId));
        if(cookieLang){
            const locale = this.langOptions.find(lang => lang.value === cookieLang.value);
            if(locale){
                this.locale = locale.valueBe;
            }
        } else {
            this.locale = this.langOptions.find(lang => lang.value === 'en-US').valueBe;
        }
        this.init();
    }

    async init(){
        if(!this.effectiveAccountId){
            const sessionContext = await getSessionContext();
            this.effectiveAccountId = sessionContext.effectiveAccountId;
            this.isLoggedIn = sessionContext.isLoggedIn;
        }

        let news = await retrieveNews({newsId: this.recordId, locale: this.locale, isLoggedIn: this.isLoggedIn});
        this.news = {...news};
        if(this.news.layout === 'Right'){
            this.news.clazz = 'image-right';
        } else if(this.news.layout === 'Center'){
            this.news.clazz = 'image-center';
        } else if(this.news.layout === 'Left'){
            this.news.clazz = 'image-left';
        }

		if(this.news.youtubeUrl){
		    this.videoBottom = this.news.videoPosition === 'On bottom';
		    this.videoTop = this.news.videoPosition === 'On top';
		    this.news.youtubeUrl = 'https://www.youtube.com/embed/' + this.news.youtubeUrl;
        }


        this.isLoading = false;
    }

}