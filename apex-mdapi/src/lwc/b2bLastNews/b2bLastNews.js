/**
 * Created by winardo on 3/13/2024.
 */

import { LightningElement, track, api } from 'lwc';
import { getSessionContext, getAppContext } from 'commerce/contextApi';

import siteId from "@salesforce/site/Id";

import retrieveLastNews from '@salesforce/apex/B2BNewsController.retrieveLastNews';

const DEFAULT_CSS = 'slds-col slds-size_1-of-1 slds-large-size_4-of-12 slds-p-around_medium slds-align_absolute-center ';
const FADEIN_CSS = DEFAULT_CSS + 'fadeIn';
const FADEOUT_CSS = DEFAULT_CSS + 'fadeOut';
const HIDE_CSS = DEFAULT_CSS + 'hide-on';

export default class B2BLastNews extends LightningElement {

	@api autoslide;
	@api autoslideSeconds;

	isMobile;

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

	locale;
	effectiveAccountId;
	isLoggedIn;
	@track page = 1;
	maxPage = 1;
	news;

	@track isLoading = true;

	connectedCallback(){
	    this.detectDeviceType();

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

		let cssObj = {
		    css: FADEOUT_CSS
        }
        let news = await retrieveLastNews({accountId: this.effectiveAccountId, locale: this.locale, isLoggedIn: this.isLoggedIn});
		news = [... news].map(n => {return {...n, ...cssObj};});
		this.maxPage = Math.ceil(news.length / 3);
		this.managePage(news);
		this.isLoading = false;
    }

    handleNext(event){
        this.page++;
        this.managePage(this.news);
    }

    handleBack(event){
        this.page--;
        this.managePage(this.news);
    }

    managePage(news){
        let i = 0;
        let startingAt = (this.page - 1) * 3;
        let endAt = startingAt + 2;
        for(let n of news){
            if(this.isMobile){
                n.css = i >= startingAt && i <= endAt ? DEFAULT_CSS : HIDE_CSS ;
            }  else {
                n.css = i >= startingAt && i <= endAt ? FADEIN_CSS : FADEOUT_CSS ;
            }

            i++;
        }
        this.news = [...news];
    }

    get isAppBuilderContext() {
        return window.location.href.includes('picasso');
    }

    get disableBack(){
        return this.page === 1 ? "disabled" : "";
    }

    get disableNext(){
        return this.page === this.maxPage ? "disabled" : "";
    }

    detectDeviceType() {
        const windowWidth = window.innerWidth;
        this.isMobile = windowWidth < 768;
    }

    get cssDivClass(){
        return this.isMobile ? 'slds-grid slds-wrap slds-align_absolute-center' : 'slds-grid slds-gutters slds-align_absolute-center';
    }

}