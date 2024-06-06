/**
 * Created by winardo on 3/13/2024.
 */

import { LightningElement, api } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';

export default class B2BNews extends NavigationMixin(LightningElement) {

	@api news;

	handleNavigate(){
	    this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.news.id,
                objectApiName: 'News__c',
                actionName: 'view',
            },
        });
    }

}