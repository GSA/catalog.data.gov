describe('Dataset', () => {

    before(() => {
        cy.login()
        cy.delete_organization('test-organization')
        cy.create_organization('test-organization', 'Test organization')
    })

    beforeEach(() => {
        Cypress.Cookies.preserveOnce('auth_tkt', 'ckan')
    })
    
    // after(() => {
    //     cy.delete_dataset('test-dataset-1')
    //     cy.delete_organization('test-organization')
    // })

    // it('Creates dataset via API', () => {
    //     cy.fixture('ckan_dataset.json').then((ckan_dataset) => {
    //         cy.create_dataset(ckan_dataset).should((response) => {
    //             expect(response.body).to.have.property('success', true)
    //         });
    //     });
    // });

    // it('Has a details page with core metadata', () => {
    //     cy.visit('/dataset/test-dataset-1');
    //     cy.contains('Test Dataset 1');
    //     // TODO: re-add the following check to validate usmetadata template is working
    //     // cy.contains('Common Core Metadata');
    // })

    // it('Add resource to private dataset via API', () => {
    //     cy.fixture('ckan_resource.csv', 'binary').then((ckan_resource) => {
    //         // File in binary format gets converted to blob so it can be sent as Form data
    //         const blob = Cypress.Blob.binaryStringToBlob(ckan_resource)
    //         const formData = new FormData();
    //         formData.set('upload', blob, 'ckan_resource.csv'); //adding a file to the form
    //         formData.set('package_id', "test-dataset-1");
    //         formData.set('name', "test-resource-1");
    //         formData.set('resource_type', "CSV");
    //         formData.set('format', "CSV");
    //         cy.form_request('POST', 'http://ckan:5000/api/action/resource_create', formData, function (response) {
    //             expect(response.status).to.eq(200);
    //         });
    //     });
    // })

    // it('Download resource file', () => {
    //     cy.visit('/dataset/test-dataset-1')
    //     // Open resource dropdown
    //     cy.get('.dropdown-toggle').click()
    //     // Download resource file
    //     cy.get('a[href*="ckan_resource.csv"]').click()
    //     // check downloaded file matches uploaded file header
    //     cy.task('isExistFile', 'ckan_resource.csv').should('contain', 'for,testing,purposes');
    // })
})
