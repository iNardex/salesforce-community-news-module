/**
 * Created by sacerra on 20/03/2024.
 */

import { LightningElement, track, api } from 'lwc';
import { getSessionContext, getAppContext } from 'commerce/contextApi';
import { NavigationMixin } from 'lightning/navigation';

import siteId from "@salesforce/site/Id";

import retrieveCarouselNews from '@salesforce/apex/B2BNewsController.retrieveCarouselNews';

export default class B2BNewsCarousel extends NavigationMixin(LightningElement) {

    @api autoslide;
    @api autoslideSeconds;

    isMobile;

    locale;
    effectiveAccountId;
    isLoggedIn;
    @track page = 0;
    haveNews = false;
    news;
    @track currentNews;

    indicators = [];

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

        console.log('NewsCarousel::effectiveAccountId::' + this.effectiveAccountId);
        console.log('NewsCarousel::isLoggedIn::' + this.isLoggedIn);

        let news = await retrieveCarouselNews({accountId: this.effectiveAccountId, locale: this.locale, isLoggedIn: this.isLoggedIn});
        this.news = [... news];
        this.haveNews = this.news.length > 0;
        if (this.haveNews) {
            this.currentNews = this.news[0];
        }
        this.indicators = Array.from({ length: this.news.length }, (_, index) => {
            return {
                class: index === this.page ? 'active' : '',
                index: index
            };
        });
        this.updateIndicators();
        console.log('NewsCarousel::news::' + JSON.stringify(this.news));
        this.isLoading = false;

        if (this.autoslide) {
            setInterval(() => {
                this.moveToNextNews();
            }, this.autoslideSeconds * 1000);
        }
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

    handleNavigate(){
        let recordId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'News__c',
                actionName: 'view',
            },
        });
    }

    updateIndicators() {
      this.indicators = this.indicators.map((indicator, index) => {
          return {
              ...indicator,
              class: index === this.page ? 'active' : '',
          };
      });
    }

    handleIndicatorClick(event) {
        const pageIndex = event.target.dataset.index;
        this.page = parseInt(pageIndex, 10);

        // Aggiorna gli indicatori
        this.updateIndicators();
        this.showNews();
    }

    showNews() {
        if (this.news && this.news.length >= this.page) {
            this.currentNews = this.news[this.page];
        }
    }

    moveToNextNews() {
        this.page = (this.page + 1) % this.news.length;
        this.updateIndicators();
        this.showNews();
    }

}