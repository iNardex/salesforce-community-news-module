/**
 * Created by winardo on 5/29/2024.
 */

public inherited sharing class UserAccountDAO {

	public static Contact getContactByUserId(Id userId){
		return getUserById(userId).Contact;
	}

	public static User getUserById(Id userId){
		return [
			SELECT Id, LanguageLocaleKey, Contact.Id, Contact.AccountId
			FROM User
			WHERE Id = :userId LIMIT 1
		];
	}

}