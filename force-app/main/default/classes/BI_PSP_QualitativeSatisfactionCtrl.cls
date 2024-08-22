/**
@description       This BI_PSP_QualitativeSatisfactionCtrl  class displays the  QSQ Questonnaire in
                   oustanding Questionnaires page based on the enrollment date of the current user.
				   we use this class in biPspbQualitativeCard.
* History:
* Version	Author		Date			Detail			Description
* 1.0		harish		05-Dec-2023		Created			Initial development.
* 1.1		harish   	01-Jan-2024		Updated			Updated for caregiver.
* 1.2		Abinsha		04-Apr-2024		Updated			Catch log added.
*/
public with sharing class BI_PSP_QualitativeSatisfactionCtrl {
    //used to store the care program enrollee id of the patient.
    private static string enrolleeId;
    //holds care program enrollee record details.
    private static List<CareProgramEnrollee> listOfEnrollee;

/**
 * @description Retrieves patient enrollee dates after two months and fourteen weeks and returns them in a map.
 * @return Map<String, Object> - A map containing target dates for two months and fourteen weeks.
 */
   @AuraEnabled(cacheable=true)
public static Map<String, Object> getPatientEnrolleeDateAfterTwoMonthsAndFourteenWeeks() {
    Map<String, Object> result = new Map<String, Object>();
    try {
        enrolleeId =BI_PSP_CurrentUser.getEnrolleeRecords()[0].id;

        List<CareProgramEnrollee> listOfEnrollee = getCareProgramEnrolleeRecords(enrolleeId);
        
        result.put('targetTwoMonthsDate', null);
        result.put('targetFourteenWeeksDate', null);

        if (!listOfEnrollee.isEmpty()) {
            processEnrolleeRecords(listOfEnrollee, result);
        } else {
            BI_PSP_LogMessagesUtility.logError(BI_PSP_QuestionnaireConstant.errorForDates, BI_PSP_QualitativeSatisfactionCtrl.class.toString(),true,BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR);
        }

        if (result.isEmpty()) {
            throw new AuraHandledException(BI_PSP_QuestionnaireConstant.errorForDates);
        }
    } catch (Exception ex) {
        BI_PSP_LogMessagesUtility.exceptionLogMessage(BI_PSP_QuestionnaireConstant.emptyEnrolleRecrd, 
                                                      BI_PSP_QualitativeSatisfactionCtrl.class.toString(), ex);
    }
    return result;
}
/**
 * @description Retrieves CareProgramEnrollee records for the given enrollee ID.
 * @param enrolleeId - The ID of the enrollee to retrieve records for.
 * @return List<CareProgramEnrollee> - A list of CareProgramEnrollee records.
 */
private static List<CareProgramEnrollee> getCareProgramEnrolleeRecords(String enrolleeId) {
    // Define the fields to retrieve
    String fields = 'Id, Name, ownerid, CreatedDate';

    String conditions = 'Id = \'' + enrolleeId + '\'';
    
    List<SObject> result = BI_PSP_CommonQueryUtility.executeQuery('CareProgramEnrollee', fields, conditions, false);
    
    return (List<CareProgramEnrollee>)result;
}
/**
 * @description Processes CareProgramEnrollee records to calculate target dates for two months and fourteen weeks from the created date.
 * @param listOfEnrollee - The list of CareProgramEnrollee records to process.
 * @param result - A map to store the calculated target dates.
 */
private static void processEnrolleeRecords(List<CareProgramEnrollee> listOfEnrollee, Map<String, Object> result) {
    for (CareProgramEnrollee enrollee : listOfEnrollee) {
        DateTime targetDateTwoMonths = enrollee.CreatedDate.addDays(BI_PSP_QuestionnaireConstant.twoMonthsInt);
        DateTime targetDateFourteenWks = enrollee.CreatedDate.addDays(BI_PSP_QuestionnaireConstant.fourteenWeeksInt);

        if (targetDateTwoMonths <= DateTime.now()) {
            result.put('targetTwoMonthsDate', targetDateTwoMonths);
        }

        if (targetDateFourteenWks <= DateTime.now()) {
            result.put('targetFourteenWeeksDate', targetDateFourteenWks);
        }
    }
}
   
/**
 * @description Retrieves completed questionnaire responses for fourteen weeks based on the provided target date.
 * @param targetDate - The target date to filter the responses.
 * @return List<AssessmentQuestionResponse> - A list of AssessmentQuestionResponse records matching the criteria.
 */
  @AuraEnabled(cacheable=true)
    public static List<AssessmentQuestionResponse> getQSQCompletedQuestionaresFourteenWks(
        String targetDate
    ) {
        List<AssessmentQuestionResponse> assessmentResponses = new List<AssessmentQuestionResponse>();
        String enrolleeId;
        
        try {
            enrolleeId = BI_PSP_CurrentUser.getEnrolleeRecords()[0].Id;
            if (!String.isBlank(targetDate)) {
                // Define fields and conditions for the query
                String fields = 'Id, AssessmentId, AssessmentQuestionId, AssessmentQuestion.QuestionText, ResponseText, ResponseValue, BI_PSP_Questionnaire_Name__c, Assessment.Id, Assessment.Name, Assessment.AssessmentStatus, Assessment.BI_PSP_DateForCQ__c, Assessment.EffectiveDateTime, Assessment.BI_PSP_RolloutforCompletedQuestionnarie__c, BI_PSP_QsqAfter2months__c, BI_PSP_QsqAfterWeeks__c, BI_PSP_ResponseOrder__c';
                String conditions = 'BI_PSP_Questionnaire_Name__c = \'' + BI_PSP_QuestionnaireConstant.qualiCategory + '\' ' +
                                    'AND Assessment.AssessmentStatus != \'' + BI_PSP_QuestionnaireConstant.inprogress + '\' ' +
                                    'AND Assessment.BI_PSP_DateForCQ__c = \'' + targetDate + '\' ' +
                                    'AND BI_PSP_QsqAfterWeeks__c = \'' + BI_PSP_QuestionnaireConstant.pageTwo + '\' ' +
                                    'AND Assessment.BI_PSP_CareProgramEnrollee__c = \'' + enrolleeId + '\' ' +
                                    'ORDER BY CreatedDate DESC, BI_PSP_ResponseOrder__c ASC';
                
                // Execute the query using the common query method
                List<SObject> queryResults = BI_PSP_CommonQueryUtility.executeQuery('AssessmentQuestionResponse', fields, conditions, false);
                
                // Cast the result to List<AssessmentQuestionResponse>
                for (SObject record : queryResults) {
                    assessmentResponses.add((AssessmentQuestionResponse) record);
                }
            } else {
                BI_PSP_LogMessagesUtility.logError(BI_PSP_QuestionnaireConstant.errorForDates, BI_PSP_QualitativeSatisfactionCtrl.class.toString(), false, BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR);
            }
            
            if (assessmentResponses.isEmpty()) {
                throw new AuraHandledException(BI_PSP_QuestionnaireConstant.emptyQuestioniareResponse);
            }
        } catch (Exception ex) {
            BI_PSP_LogMessagesUtility.exceptionLogMessage(ex.getMessage(), BI_PSP_QualitativeSatisfactionCtrl.class.toString(), ex);
        }
        return assessmentResponses;
    }

  /**
 * @description Retrieves expired questionnaire responses for fourteen weeks by querying related Assessment records.
 * @return List<Assessment> - A list of Assessment records that are associated with expired questionnaire responses.
 */
    @AuraEnabled(cacheable=true)
    public static List<Assessment> getQSQExpiredQuestionnaireFourteenWks() {
        List<Assessment> assessmentResponses = new List<Assessment>();
        Set<Id> responseIds = new Set<Id>();
        try {
           	enrolleeId =BI_PSP_CurrentUser.getEnrolleeRecords()[0].id;
            /* USER_MODE is not used because AssessmentQuestionResponse is an Salesforce Industry object
             using Healthcare license*/

           // Define fields and conditions for the first query
            String fieldsResponse = 'Id, BI_PSP_QsqAfterWeeks__c, AssessmentId';
            String conditionsResponse = 'BI_PSP_QsqAfterWeeks__c = \'' + BI_PSP_QuestionnaireConstant.pageTwo + '\'';
            
            // Execute the first query using the common query method
            List<SObject> queryResultsResponse = BI_PSP_CommonQueryUtility.executeQuery('AssessmentQuestionResponse', fieldsResponse, conditionsResponse, false);
            
            // Extract AssessmentIds from the results
            for (SObject record : queryResultsResponse) {
                AssessmentQuestionResponse response = (AssessmentQuestionResponse) record;
                responseIds.add(response.AssessmentId);
            }
            
            if (responseIds.isEmpty()) {
                BI_PSP_LogMessagesUtility.logError(BI_PSP_QuestionnaireConstant.emptyQuestioniareResponse, BI_PSP_QualitativeSatisfactionCtrl.class.toString(), false, BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR);
            }
            // Query Assessment records using the IDs of AssessmentQuestionResponses
            /* USER_MODE is not used because CareProgramEnrollee is an Salesforce Industry object
             using Healthcare license*/
            if (
                (enrolleeId != null && !String.isBlank(enrolleeId)) &&
                (responseIds != null && !responseIds.isEmpty())
            ) {
        List<String> fieldsList = new List<String>{
        'Id',
        'Name',
        'EffectiveDateTime',
        'ExpirationDateTime'
    };
    // Convert List<String> to a comma-separated string
    String responseIdsStr = '\'' + String.join(responseIds, '\', \'') + '\'';

    // Construct the dynamic query
    String query = 'SELECT ' + String.join(fieldsList, ', ') + 
                   ' FROM Assessment' +
                   ' WHERE Name = \'' + BI_PSP_QuestionnaireConstant.qualiCategory + '\'' +
                   ' AND BI_PSP_CareProgramEnrollee__c = \'' + enrolleeId + '\'' +
                   ' AND Id IN (' + responseIdsStr + ')' + 
                   ' ORDER BY CreatedDate DESC';
    // Execute the query
    List<SObject> queryResponse = BI_PSP_CommonQueryUtility.executeComplexQuery(query, false);
    assessmentResponses = (List<Assessment>) queryResponse;
                
            } else {
                BI_PSP_LogMessagesUtility.logError(BI_PSP_QuestionnaireConstant.emptyEnrolleRecrd,BI_PSP_QualitativeSatisfactionCtrl.class.toString(),true,BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR);
            }
            if (assessmentResponses.isEmpty()) {
                BI_PSP_LogMessagesUtility.logError(BI_PSP_QuestionnaireConstant.emptyAssesment,BI_PSP_QualitativeSatisfactionCtrl.class.toString(),false,BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR);
               
            }
        } catch (Exception ex) {
            BI_PSP_LogMessagesUtility.exceptionLogMessage(ex.getMessage(),BI_PSP_QualitativeSatisfactionCtrl.class.toString(),ex);
        }
        return assessmentResponses;
    }
}