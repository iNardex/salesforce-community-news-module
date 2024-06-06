/**
 * Created by winardo on 3/13/2024.
 */

import { LightningElement, track, api } from 'lwc';
import { getSessionContext, getAppContext } from 'commerce/contextApi';

import siteId from "@salesforce/site/Id";

import retrieveAllNews from '@salesforce/apex/B2BNewsController.retrieveAllNews';
import getTopicPicklistValues from '@salesforce/apex/B2BNewsController.getTopicPicklistValues';

export default class B2BAllNews extends LightningElement {

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

	limit = 9;
	offset = 0

	news;
	empty = false;
	totalCount;

	@track loadMoreLoading = false;
	@track isLoading = true;
	@track tagList = [];
	@track filteredNews = [];
	@track topic = 'All';

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

        let news = await retrieveAllNews({accountId: this.effectiveAccountId, locale: this.locale, isLoggedIn: this.isLoggedIn, lim: this.limit, offset: this.offset, topic: this.topic});
		this.news = [... news];
		this.filteredNews = this.news;
		console.log('News: ' + JSON.stringify(this.news));
		this.empty = this.news.length === 0;
		this.totalCount = this.empty ? 0 : this.news[0].totalNews;

        let newTags = [];
        const topicPicklistValues = await getTopicPicklistValues();
        topicPicklistValues.forEach(topic => {
            newTags.push({ name: topic, selected: false, className: '' });
        });

        newTags.sort((a, b) => a.name.localeCompare(b.name));
        newTags.unshift({ name: 'All', selected: true, className: '' });
        this.tagList = newTags;

        this.tagList.forEach(tag => {
            tag.className = tag.selected ? 'selected' : '';
        });

        console.log('TAG: ' + JSON.stringify(this.tagList));

		this.isLoading = false;
    }

    handleLoadMore(){
        this.loadMoreLoading = true;
        this.offset += this.limit;
        this.loadMore();
    }

    get loadMoreVisible(){
        if(this.empty){
            return false;
        }
        let page = this.totalCount / this.limit;
        return ( this.news.length / this.limit ) < page;
    }

//    async loadMore(){
//        let news = await retrieveAllNews({accountId: this.effectiveAccountId, locale: this.locale, isLoggedIn: this.isLoggedIn, lim: this.limit, offset: this.offset});
//        this.news = [...this.news, ...news];
//        this.loadMoreLoading = false;
//    }

    async loadMore(){
        let news = await retrieveAllNews({accountId: this.effectiveAccountId, locale: this.locale, isLoggedIn: this.isLoggedIn, lim: this.limit, offset: this.offset, topic: this.topic});
        this.news = [...this.news, ...news];
        this.filteredNews = this.news;

        this.filterNewsByTag();
        this.loadMoreLoading = false;
    }


    async handleTagClick(event) {
        this.isLoading = true;
        const selectedTagName = event.currentTarget.dataset.name;
        this.tagList.forEach(tag => {
            tag.selected = tag.name === selectedTagName;
            tag.className = tag.selected ? 'selected' : '';
        });

        this.topic = selectedTagName;
        let news = await retrieveAllNews({accountId: this.effectiveAccountId, locale: this.locale, isLoggedIn: this.isLoggedIn, lim: this.limit, offset: this.offset, topic: this.topic});
        this.news = [...news];
        this.filteredNews = this.news;

        this.filterNewsByTag();
        this.isLoading = false;

        console.log('News: ' + JSON.stringify(this.news));
        console.log('TAG: ' + JSON.stringify(this.tagList));
    }

    filterNewsByTag() {
        if (this.tagList.some(tag => tag.selected)) {
            const selectedTag = this.tagList.find(tag => tag.selected);
            if (selectedTag.name === 'All') {
                this.filteredNews = this.news;
            } else {
                this.filteredNews = this.news.filter(item => item.tag === selectedTag.name);
            }
        } else {
            this.filteredNews = this.news;
        }
        this.empty = this.filteredNews.length === 0;
        this.totalCount = this.empty ? 0 : this.filteredNews[0].totalNews;
    }
}