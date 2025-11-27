import SwiftUI

struct QuestionView: View {
    let question: Question
    let selectedOptionIndex: Int?
    let onSelect: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.text)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.bottom, 10)
            
            ForEach(0..<question.options.count, id: \.self) { index in
                Button(action: {
                    onSelect(index)
                }) {
                    HStack {
                        Text(question.options[index].text)
                            .font(.body)
                            .foregroundColor(selectedOptionIndex == index ? .white : .textPrimary)
                        
                        Spacer()
                        
                        if selectedOptionIndex == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedOptionIndex == index ? Color.primaryPurple : Color.backgroundSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedOptionIndex == index ? Color.primaryPurple : Color.borderPrimary, lineWidth: selectedOptionIndex == index ? 2 : 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
    }
}

struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionView(
            question: RiskEngine.shared.questions[0],
            selectedOptionIndex: nil,
            onSelect: { _ in }
        )
    }
}
