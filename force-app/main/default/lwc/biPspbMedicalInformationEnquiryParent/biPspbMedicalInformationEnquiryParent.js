// This LWC is a design for Medical Information Enquiry main page which contains the consolidated components like Avatar and releavant Messages
// To import Libraries
import { LightningElement} from 'lwc';
// To import Custom Labels
import{support} from 'c/biPspbSupportCaseResources';
export default class BiPspbMedicalInformationEnquiryParent extends LightningElement 
{
	// Declaration of variables with @track
	supportCenter = support.SUPPORT_CENTER;
	myCase = support.MYCASE;
	valueError;
	connectedCallback()
	{
		let globalThis = window;
		try
		{
			const CURRENT_URL = globalThis.location.href;  // Create a URL object
			const URL_OBJECT = new URL(CURRENT_URL);  // Get the PATH
			const PATH = URL_OBJECT.pathname;  // Split the PATH using '/' as a separator
			const PATH_COMPONENTS = PATH.split('/');  // Find the component you need (in this case, 'Branded')
			const DESIRED_COMPONENT = PATH_COMPONENTS.find(component =>
				[support.BRANDED_URL.toLowerCase(), support.UNASSIGNED_URL.toLowerCase()].includes(component.toLowerCase())
			);

			if (DESIRED_COMPONENT.toLowerCase() === support.BRANDED_URL.toLowerCase()) {
				this.urlq = support.BRANDED_URL_NAVI;
			}
			else {
				this.urlq = support.UNASSIGNED_URL_NAVI;
			}
		}
		catch(error)
		{
			this.showToast(error.message);
		}
	}
	// To navidate to the My Support page
	openSupportCenter() {
		window.location.assign(this.urlq + support.SUPPORT_PAGE_URL);
	}
	// To navigate to the My Cases page
	openMyCases() {
		window.location.assign(this.urlq + support.MY_CASE_URL);
	}
	showToast(errorMessage) {
		let global = window;
	global.location?.assign(this.urlq + support.ERROR_PAGE);
	global.sessionStorage.setItem('errorMessage', errorMessage);
	}
	isMedicalValid = false;

	avatarContent = false;

    handleDescriptionError(event) {
        this.avatarContent = event.detail.error;
    }
	
}