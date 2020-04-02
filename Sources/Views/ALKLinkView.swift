import Foundation
import Kingfisher

class ALKLinkView: UIView {
    var localizedStringFileName: String!

    public func setLocalizedStringFileName(_ localizedStringFileName: String) {
        self.localizedStringFileName = localizedStringFileName
    }

    let loadingIndicator = ALKLoadingIndicator(frame: .zero, color: UIColor.red)
    enum CommonPadding {
        enum PreviewImageView {
            static let top: CGFloat = 5
            static let leading: CGFloat = 5
            static let height: CGFloat = 60
            static let width: CGFloat = 60
        }

        enum TitleLabel {
            static let top: CGFloat = 5
            static let leading: CGFloat = 5
            static let height: CGFloat = 30
            static let trailing: CGFloat = 5
        }

        enum DescriptionLabel {
            static let top: CGFloat = 5
            static let leading: CGFloat = 5
            static let height: CGFloat = 30
            static let trailing: CGFloat = 5
        }
    }

    var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.font(.bold(size: 14))
        label.text = "This title is now"
        label.numberOfLines = 2
        return label
    }()

    var descriptionLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 2
        label.text = "This description Label"
        label.textColor = UIColor.lightGray
        label.font = UIFont.font(.normal(size: 12))
        return label
    }()

    let previewImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.image = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        imageView.backgroundColor = .clear
        return imageView
    }()

    init() {
        super.init(frame: .zero)
        setupConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        addViewsForAutolayout(views: [titleLabel, descriptionLabel, previewImageView, loadingIndicator])

        previewImageView.topAnchor.constraint(equalTo: topAnchor, constant: CommonPadding.PreviewImageView.top).isActive = true
        previewImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CommonPadding.PreviewImageView.leading).isActive = true
        previewImageView.widthAnchor.constraint(equalToConstant: CommonPadding.PreviewImageView.width).isActive = true
        previewImageView.heightAnchor.constraint(equalToConstant: CommonPadding.PreviewImageView.height).isActive = true

        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: CommonPadding.TitleLabel.top).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: previewImageView.trailingAnchor, constant: CommonPadding.TitleLabel.leading).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: CommonPadding.TitleLabel.height).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CommonPadding.TitleLabel.trailing).isActive = true

        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: CommonPadding.DescriptionLabel.top).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: previewImageView.trailingAnchor, constant: CommonPadding.DescriptionLabel.leading).isActive = true
        descriptionLabel.heightAnchor.constraint(equalToConstant: CommonPadding.DescriptionLabel.height).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant:
            -CommonPadding.DescriptionLabel.trailing).isActive = true

        loadingIndicator.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        loadingIndicator.topAnchor.constraint(equalTo: topAnchor).isActive = true
        loadingIndicator.bottomAnchor.constraint(equalTo: descriptionLabel.bottomAnchor).isActive = true
        loadingIndicator.leadingAnchor.constraint(equalTo: previewImageView.leadingAnchor).isActive = true
    }

    func update(url: String?) {
        loadingIndicator.startLoading(localizationFileName: localizedStringFileName)
        hideViews(true)
        guard let linkUrl = url else {
            loadingIndicator.stopLoading()
            hideViews(false)
            return
        }
        guard let cachelinkViewModel = LinkURLCache.getLink(for: linkUrl) else {
            let linkview = ALKLinkPreview()
            linkview.makePreview(from: linkUrl) { result in
                switch result {
                case let .success(linkViewModel):
                    self.update(linkViewModel: linkViewModel)
                case .failure:
                    print("Error while fetching the url data")
                    self.loadingIndicator.stopLoading()
                }
            }
            return
        }
        update(linkViewModel: cachelinkViewModel)
    }

    func hideViews(_ isHide: Bool) {
        previewImageView.isHidden = isHide
        titleLabel.isHidden = isHide
        descriptionLabel.isHidden = isHide
    }

    func update(linkViewModel: LinkPreviewMeta) {
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let stringURL = linkViewModel.icon, let url = URL(string: stringURL) {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            previewImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            previewImageView.image = placeHolder
        }

        titleLabel.text = linkViewModel.title
        descriptionLabel.text = linkViewModel.description ?? linkViewModel.getBaseURl(url: linkViewModel.url?.absoluteString ?? "")
        hideViews(false)
        loadingIndicator.stopLoading()
    }
}
