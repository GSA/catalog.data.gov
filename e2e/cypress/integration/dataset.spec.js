describe('Dataset', () => {
    // Uses datasets from data.json local harvest to check
    
    it('Has a details page with core metadata', () => {
        cy.visit('/dataset/data-gov-statistics-parent');
        cy.contains('Data.gov Statistics Parent');
        cy.contains('Metadata Source');
        cy.contains('Additional Metadata');
        cy.contains('Identifier');
        cy.contains('Publisher');
        cy.contains('Bureau Code');
    })

    it('Can see resource pages', () => {
        cy.visit('/dataset/2015-gsa-common-baseline-implementation-plan-and-cio-assignment-plan');
        // Hide flask debug toolbar
        cy.get('#flHideToolBarButton').click();

        // Click on the resource link
        cy.contains('2015 GSA Common Baseline Implementation Plan...').click();
        cy.contains('About this Resource');
        cy.contains("Download");
    })
})
