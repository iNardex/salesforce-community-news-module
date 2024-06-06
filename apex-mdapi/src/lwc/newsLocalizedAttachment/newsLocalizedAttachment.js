/**
 * Created by winardo on 3/11/2024.
 */

import { LightningElement, api, track } from 'lwc';
import retrieveNewsLocalized from "@salesforce/apex/B2BNewsLocalizedController.retrieveNewsLocalized";
import createAttachment from "@salesforce/apex/B2BNewsLocalizedController.createAttachment";
import deleteAttachment from "@salesforce/apex/B2BNewsLocalizedController.deleteAttachment";

export default class NewsLocalizedAttachment extends LightningElement {

	@api recordId;
	@api mode;
	@track isLoading = true;
	imageUrl;

	connectedCallback(){
		this.init();
    }

    async init(){
        let loc = await retrieveNewsLocalized({newsLocalizedId : this.recordId});
        this.imageUrl = this.mode === 'Carousel' ? loc.CarouselImageUrl__c : loc.DetailImageUrl__c;
        this.isLoading = false;
    }

    handleFileUpload(event) {
        this.isLoading = true;
        let documentId = event.detail.files[0].documentId;
        createAttachment({newsLocalizedId : this.recordId, attachmentId: documentId, mode : this.mode})
        .then((result) => {
            this.imageUrl = result;
            this.isLoading = false;
        }).catch((error) => {
            this.isLoading = false;
        });
    }

    handleRemove(event){
        this.isLoading = true;
		deleteAttachment({newsLocalizedId : this.recordId, mode : this.mode})
		.then((result) => {
            this.imageUrl = undefined;
            this.isLoading = false;
        }).catch((error) => {
            this.isLoading = false;
        });
    }

    get acceptedFormats() {
        return [".jpg", ".jpeg", ".png"];
    }

    get title(){
        return this.mode === 'Carousel' ? 'Carousel image' : 'Detail image';
    }

}